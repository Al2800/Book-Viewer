#!/usr/bin/env node

const fs = require("fs");
const crypto = require("crypto");
const https = require("https");

const DEFAULT_CONFIG_PATH =
  "/Volumes/Macintosh_HD/Users/user298279/.appstoreconnect/config.json";
const DEFAULT_BUNDLE_ID = "com.acampbell.bookquotes";

const args = new Set(process.argv.slice(2));
const configPath = process.env.ASC_CONFIG_PATH || DEFAULT_CONFIG_PATH;
const appIdOverride = process.env.ASC_APP_ID;
const bundleId = process.env.ASC_BUNDLE_ID || DEFAULT_BUNDLE_ID;
const buildNumber = process.env.BUILD_NUMBER || process.env.ASC_BUILD_NUMBER || "22";
const shouldSetEncryptionFalse = args.has("--set-encryption-false");

function loadConfig() {
  const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
  for (const key of ["issuerId", "keyId", "privateKeyPath"]) {
    if (!config[key]) {
      throw new Error(`Missing ${key} in ${configPath}`);
    }
  }
  return config;
}

function base64url(input) {
  return Buffer.from(input)
    .toString("base64")
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}

function createJwt(config) {
  const key = fs.readFileSync(config.privateKeyPath, "utf8");
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "ES256", kid: config.keyId, typ: "JWT" };
  const payload = {
    iss: config.issuerId,
    exp: now + 20 * 60,
    aud: "appstoreconnect-v1",
  };

  if (config.subject) {
    payload.sub = config.subject;
  }

  const signingInput = `${base64url(JSON.stringify(header))}.${base64url(
    JSON.stringify(payload)
  )}`;
  const signature = crypto.sign("sha256", Buffer.from(signingInput), {
    key,
    dsaEncoding: "ieee-p1363",
  });

  return `${signingInput}.${base64url(signature)}`;
}

function ascRequest(config, method, path, body) {
  return new Promise((resolve, reject) => {
    const rawBody = body ? JSON.stringify(body) : null;
    const request = https.request(
      {
        hostname: "api.appstoreconnect.apple.com",
        method,
        path,
        headers: {
          Authorization: `Bearer ${createJwt(config)}`,
          ...(rawBody
            ? {
                "Content-Type": "application/json",
                "Content-Length": Buffer.byteLength(rawBody),
              }
            : {}),
        },
      },
      (response) => {
        let responseBody = "";
        response.on("data", (chunk) => {
          responseBody += chunk;
        });
        response.on("end", () => {
          let parsed = null;
          if (responseBody) {
            try {
              parsed = JSON.parse(responseBody);
            } catch {
              parsed = responseBody;
            }
          }
          resolve({ status: response.statusCode, body: parsed });
        });
      }
    );

    request.on("error", reject);
    if (rawBody) {
      request.write(rawBody);
    }
    request.end();
  });
}

function query(params) {
  return new URLSearchParams(params).toString();
}

async function getAppId(config) {
  if (appIdOverride) {
    return appIdOverride;
  }

  const response = await ascRequest(
    config,
    "GET",
    `/v1/apps?${query({ "filter[bundleId]": bundleId, limit: "1" })}`
  );
  if (response.status !== 200) {
    throw new Error(`App lookup failed: ${JSON.stringify(response.body)}`);
  }

  const app = response.body.data?.[0];
  if (!app) {
    throw new Error(`No App Store Connect app found for bundle id ${bundleId}`);
  }
  return app.id;
}

async function getBuilds(config, appId) {
  const response = await ascRequest(
    config,
    "GET",
    `/v1/builds?${query({
      "filter[app]": appId,
      "filter[version]": buildNumber,
      "fields[builds]":
        "version,processingState,uploadedDate,expired,usesNonExemptEncryption",
      sort: "-uploadedDate",
      limit: "10",
    })}`
  );
  if (response.status !== 200) {
    throw new Error(`Build lookup failed: ${JSON.stringify(response.body)}`);
  }

  return response.body.data || [];
}

async function getGroups(config, appId) {
  const response = await ascRequest(
    config,
    "GET",
    `/v1/betaGroups?${query({
      "filter[app]": appId,
      "fields[betaGroups]":
        "name,isInternalGroup,hasAccessToAllBuilds,publicLinkEnabled",
      limit: "200",
    })}`
  );
  if (response.status !== 200) {
    throw new Error(`Beta group lookup failed: ${JSON.stringify(response.body)}`);
  }

  const groups = response.body.data || [];
  const groupDetails = [];
  for (const group of groups) {
    const testersResponse = await ascRequest(
      config,
      "GET",
      `/v1/betaGroups/${group.id}/betaTesters?${query({
        "fields[betaTesters]": "firstName,lastName,email",
        limit: "200",
      })}`
    );

    groupDetails.push({
      id: group.id,
      ...group.attributes,
      testers:
        testersResponse.status === 200
          ? (testersResponse.body.data || []).map((tester) => ({
              id: tester.id,
              ...tester.attributes,
            }))
          : { status: testersResponse.status, body: testersResponse.body },
    });
  }

  return groupDetails;
}

async function setEncryptionFalse(config, build) {
  const response = await ascRequest(config, "PATCH", `/v1/builds/${build.id}`, {
    data: {
      type: "builds",
      id: build.id,
      attributes: { usesNonExemptEncryption: false },
    },
  });

  if (response.status !== 200) {
    throw new Error(`Encryption update failed: ${JSON.stringify(response.body)}`);
  }
}

async function main() {
  const config = loadConfig();
  const appId = await getAppId(config);
  const builds = await getBuilds(config, appId);

  if (shouldSetEncryptionFalse && builds[0]) {
    await setEncryptionFalse(config, builds[0]);
  }

  const refreshedBuilds = shouldSetEncryptionFalse ? await getBuilds(config, appId) : builds;
  const groups = await getGroups(config, appId);

  console.log(
    JSON.stringify(
      {
        appId,
        bundleId,
        requestedBuildNumber: buildNumber,
        config: {
          keyId: config.keyId,
          privateKeyPath: config.privateKeyPath,
          subject: config.subject || null,
        },
        builds: refreshedBuilds.map((build) => ({ id: build.id, ...build.attributes })),
        betaGroups: groups,
      },
      null,
      2
    )
  );
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
