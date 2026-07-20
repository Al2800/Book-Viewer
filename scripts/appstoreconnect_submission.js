#!/usr/bin/env node

const fs = require("fs");
const crypto = require("crypto");
const https = require("https");
const os = require("os");
const path = require("path");

const DEFAULT_CONFIG_PATH = path.join(os.homedir(), ".appstoreconnect", "config.json");
const DEFAULT_BUNDLE_ID = "com.acampbell.bookquotes";
const SUBMITTED_REVIEW_STATES = new Set([
  "WAITING_FOR_REVIEW",
  "IN_REVIEW",
  "UNRESOLVED_ISSUES",
  "CANCELING",
  "COMPLETING",
]);
const APP_DESCRIPTION = `Capture marked book pages and build a searchable library of your favourite quotes.

- Add books by scanning ISBN barcodes or entering details manually
- Capture single pages or use batch mode
- Review and edit extracted quotes before saving
- Organise with collections, tags, and custom marking types
- Export to Markdown, plain text, JSON, Obsidian, and Notion

Remote AI extraction is optional, requires a subscription and explicit consent, and always provides an on-device fallback. No tracking or ads. Books, quotes, tags, collections, and captured images remain on your device.`;
const APP_REVIEW_NOTES = `No account is required to use the app's core on-device features. Reviewers can choose Continue Without an Account during onboarding, then add and manage books, capture marked pages with on-device OCR, search the local library, export quotes, and change Settings. Eligible, consented subscribers use remote AI first for marked-page extraction. A remote failure is shown explicitly with Retry AI, Use On-Device Instead, and manual-entry recovery choices.

Apple Sign In is requested only when the reviewer chooses an account-only feature: remote AI processing or subscription purchase/restoration. Remote AI processing also requires a separate, revocable image-sharing consent. Books, quotes, and captured images remain local to the device; signing out or deleting a server account does not delete the local library.

Books are added by ISBN barcode catalogue lookup or manual entry. Book covers come from ISBN catalogue metadata and are not sent to an AI provider.

The monthly and yearly auto-renewable subscriptions unlock remote AI processing. StoreKit sandbox may be used to purchase or restore. Account deletion is available at Settings > Account > Delete Account; Apple subscriptions remain managed by Apple.`;

const args = new Set(process.argv.slice(2));
const configPath = expandHomeDirectory(process.env.ASC_CONFIG_PATH || DEFAULT_CONFIG_PATH);
const bundleId = process.env.ASC_BUNDLE_ID || DEFAULT_BUNDLE_ID;
const versionString = process.env.ASC_VERSION || "1.0";
const buildNumber = process.env.BUILD_NUMBER || process.env.ASC_BUILD_NUMBER || "45";
const appIdOverride = process.env.ASC_APP_ID;

function expandHomeDirectory(filePath) {
  if (filePath === "~") return os.homedir();
  return filePath.startsWith("~/") ? path.join(os.homedir(), filePath.slice(2)) : filePath;
}

function loadConfig() {
  const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
  for (const key of ["issuerId", "keyId", "privateKeyPath"]) {
    if (!config[key]) throw new Error(`Missing ${key} in ${configPath}`);
  }
  config.privateKeyPath = expandHomeDirectory(config.privateKeyPath);
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
  const payload = { iss: config.issuerId, exp: now + 20 * 60, aud: "appstoreconnect-v1" };
  if (config.subject) payload.sub = config.subject;
  const signingInput = `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(payload))}`;
  const signature = crypto.sign("sha256", Buffer.from(signingInput), {
    key,
    dsaEncoding: "ieee-p1363",
  });
  return `${signingInput}.${base64url(signature)}`;
}

function ascRequest(config, method, requestPath, body) {
  return new Promise((resolve, reject) => {
    const rawBody = body ? JSON.stringify(body) : null;
    const request = https.request(
      {
        hostname: "api.appstoreconnect.apple.com",
        method,
        path: requestPath,
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
    if (rawBody) request.write(rawBody);
    request.end();
  });
}

function query(params) {
  return new URLSearchParams(params).toString();
}

async function requireResponse(config, method, requestPath, body, expected = [200]) {
  const response = await ascRequest(config, method, requestPath, body);
  if (!expected.includes(response.status)) {
    throw new Error(
      `${method} ${requestPath} failed (${response.status}): ${JSON.stringify(response.body)}`
    );
  }
  return response.body;
}

async function getApp(config) {
  if (appIdOverride) return { id: appIdOverride, attributes: { bundleId } };
  const body = await requireResponse(
    config,
    "GET",
    `/v1/apps?${query({ "filter[bundleId]": bundleId, "fields[apps]": "name,bundleId,sku", limit: "1" })}`
  );
  if (!body.data?.[0]) throw new Error(`No App Store Connect app found for ${bundleId}`);
  return body.data[0];
}

async function getVersion(config, appId) {
  const body = await requireResponse(
    config,
    "GET",
    `/v1/apps/${appId}/appStoreVersions?${query({
      "filter[platform]": "IOS",
      "filter[versionString]": versionString,
      "fields[appStoreVersions]":
        "platform,versionString,appStoreState,appVersionState,copyright,reviewType,releaseType,earliestReleaseDate,usesIdfa,downloadable,createdDate",
      limit: "10",
    })}`
  );
  const candidates = body.data || [];
  const editable = candidates.find((item) => item.attributes?.appVersionState === "PREPARE_FOR_SUBMISSION");
  return editable || candidates[0] || null;
}

async function getBuild(config, appId) {
  const body = await requireResponse(
    config,
    "GET",
    `/v1/builds?${query({
      "filter[app]": appId,
      "filter[version]": buildNumber,
      "fields[builds]": "version,processingState,uploadedDate,expired,usesNonExemptEncryption",
      sort: "-uploadedDate",
      limit: "10",
    })}`
  );
  return body.data?.[0] || null;
}

async function getRelationship(config, type, id, relationship) {
  const body = await requireResponse(config, "GET", `/v1/${type}/${id}/${relationship}`);
  return body.data;
}

async function getLocalizations(config, versionId) {
  const body = await requireResponse(
    config,
    "GET",
    `/v1/appStoreVersions/${versionId}/appStoreVersionLocalizations?${query({
      "fields[appStoreVersionLocalizations]":
        "locale,description,keywords,marketingUrl,promotionalText,supportUrl,whatsNew",
      limit: "50",
    })}`
  );
  const localizations = [];
  for (const localization of body.data || []) {
    const screenshotBody = await requireResponse(
      config,
      "GET",
      `/v1/appStoreVersionLocalizations/${localization.id}/appScreenshotSets?${query({
        "fields[appScreenshotSets]": "screenshotDisplayType,appScreenshots",
        "fields[appScreenshots]": "fileName,fileSize,assetDeliveryState,assetToken,sourceFileChecksum",
        include: "appScreenshots",
        "limit[appScreenshots]": "10",
        limit: "50",
      })}`
    );
    const included = screenshotBody.included || [];
    localizations.push({
      id: localization.id,
      ...localization.attributes,
      screenshotSets: (screenshotBody.data || []).map((set) => ({
        id: set.id,
        displayType: set.attributes?.screenshotDisplayType,
        screenshots: included
          .filter((item) => item.type === "appScreenshots")
          .filter((item) => set.relationships?.appScreenshots?.data?.some((ref) => ref.id === item.id))
          .map((item) => ({ id: item.id, ...item.attributes })),
      })),
    });
  }
  return localizations;
}

async function getReviewDetail(config, versionId) {
  const body = await requireResponse(
    config,
    "GET",
    `/v1/appStoreVersions/${versionId}/appStoreReviewDetail?${query({
      "fields[appStoreReviewDetails]":
        "contactFirstName,contactLastName,contactPhone,contactEmail,demoAccountName,demoAccountPassword,demoAccountRequired,notes",
    })}`
  );
  return body.data || null;
}

async function getAppInfos(config, appId) {
  const body = await requireResponse(
    config,
    "GET",
    `/v1/apps/${appId}/appInfos?${query({
      "fields[appInfos]": "appStoreAgeRating,appInfoLocalizations,ageRatingDeclaration,primaryCategory,primarySubcategoryOne,primarySubcategoryTwo,secondaryCategory,secondarySubcategoryOne,secondarySubcategoryTwo",
      "fields[appInfoLocalizations]": "locale,name,subtitle,privacyPolicyUrl,privacyChoicesUrl,privacyPolicyText",
      "fields[ageRatingDeclarations]": "advertising,alcoholTobaccoOrDrugUseOrReferences,contests,gambling,gamblingSimulated,gunsOrOtherWeapons,horrorOrFearThemes,lootBox,matureOrSuggestiveThemes,medicalOrTreatmentInformation,parentalControls,profanityOrCrudeHumor,sexualContentGraphicAndNudity,sexualContentOrNudity,unrestrictedWebAccess,userGeneratedContent,ageAssurance,ageRatingOverride,healthOrWellnessTopics,messagingAndChat",
      include: "appInfoLocalizations,ageRatingDeclaration",
      limit: "10",
      "limit[appInfoLocalizations]": "50",
    })}`
  );
  return body;
}

async function getReviewSubmissions(config, appId) {
  const body = await requireResponse(
    config,
    "GET",
    `/v1/apps/${appId}/reviewSubmissions?${query({
      "fields[reviewSubmissions]": "platform,submittedDate,state,items,appStoreVersionForReview",
      "fields[reviewSubmissionItems]": "state,appStoreVersion",
      "fields[appStoreVersions]": "platform,versionString,appStoreState,appVersionState",
      include: "items,appStoreVersionForReview",
      limit: "50",
      "limit[items]": "50",
    })}`
  );
  return { data: body.data || [], included: body.included || [] };
}

async function getSubscriptions(config, appId) {
  const groupsBody = await requireResponse(
    config,
    "GET",
    `/v1/apps/${appId}/subscriptionGroups?${query({
      "fields[subscriptionGroups]": "referenceName,subscriptions",
      limit: "50",
    })}`
  );
  const groups = [];
  for (const group of groupsBody.data || []) {
    const subscriptionsBody = await requireResponse(
      config,
      "GET",
      `/v1/subscriptionGroups/${group.id}/subscriptions?${query({
        "fields[subscriptions]":
          "name,productId,familySharable,state,subscriptionPeriod,groupLevel,reviewNote,subscriptionLocalizations,appStoreReviewScreenshot",
        limit: "50",
      })}`
    );
    const subscriptions = [];
    for (const subscription of subscriptionsBody.data || []) {
      const localizations = await getRelationship(
        config,
        "subscriptions",
        subscription.id,
        "subscriptionLocalizations"
      );
      const screenshot = await getRelationship(
        config,
        "subscriptions",
        subscription.id,
        "appStoreReviewScreenshot"
      );
      subscriptions.push({
        id: subscription.id,
        ...subscription.attributes,
        localizations: (localizations || []).map((item) => ({ id: item.id, ...item.attributes })),
        reviewScreenshot: screenshot ? { id: screenshot.id, ...screenshot.attributes } : null,
      });
    }
    groups.push({ id: group.id, ...group.attributes, subscriptions });
  }
  return groups;
}

async function attachBuild(config, versionId, buildId) {
  await requireResponse(
    config,
    "PATCH",
    `/v1/appStoreVersions/${versionId}/relationships/build`,
    { data: { type: "builds", id: buildId } },
    [204]
  );
}

async function updateReviewNotes(config, reviewDetail) {
  await requireResponse(
    config,
    "PATCH",
    `/v1/appStoreReviewDetails/${reviewDetail.id}`,
    {
      data: {
        type: "appStoreReviewDetails",
        id: reviewDetail.id,
        attributes: { notes: APP_REVIEW_NOTES },
      },
    }
  );
}

async function updateMetadata(config, localization) {
  await requireResponse(
    config,
    "PATCH",
    `/v1/appStoreVersionLocalizations/${localization.id}`,
    {
      data: {
        type: "appStoreVersionLocalizations",
        id: localization.id,
        attributes: {
          description: APP_DESCRIPTION,
          promotionalText: "Scan books by ISBN, capture marked pages, and keep your best lines organised.",
        },
      },
    }
  );
}

function findDraftForVersion(reviewSubmissions, versionId) {
  return reviewSubmissions.data.find(
    (submission) =>
      submission.attributes?.state === "READY_FOR_REVIEW" &&
      submission.relationships?.appStoreVersionForReview?.data?.id === versionId
  );
}

function findSubmittedReviewSubmission(reviewSubmissions) {
  return reviewSubmissions.data.find((submission) =>
    SUBMITTED_REVIEW_STATES.has(submission.attributes?.state)
  );
}

function findReusableEmptyDraft(reviewSubmissions) {
  return reviewSubmissions.data.find(
    (submission) =>
      submission.attributes?.state === "READY_FOR_REVIEW" &&
      (submission.relationships?.items?.data?.length || 0) === 0
  );
}

async function createReviewSubmission(config, appId) {
  const body = await requireResponse(
    config,
    "POST",
    "/v1/reviewSubmissions",
    {
      data: {
        type: "reviewSubmissions",
        attributes: { platform: "IOS" },
        relationships: { app: { data: { type: "apps", id: appId } } },
      },
    },
    [201]
  );
  return body.data;
}

async function addVersionToReview(config, reviewSubmissionId, versionId) {
  const body = await requireResponse(
    config,
    "POST",
    "/v1/reviewSubmissionItems",
    {
      data: {
        type: "reviewSubmissionItems",
        relationships: {
          reviewSubmission: {
            data: { type: "reviewSubmissions", id: reviewSubmissionId },
          },
          appStoreVersion: { data: { type: "appStoreVersions", id: versionId } },
        },
      },
    },
    [201]
  );
  return body.data;
}

async function submitReview(config, reviewSubmissionId) {
  return requireResponse(config, "PATCH", `/v1/reviewSubmissions/${reviewSubmissionId}`, {
    data: {
      type: "reviewSubmissions",
      id: reviewSubmissionId,
      attributes: { submitted: true },
    },
  });
}

async function submitSubscription(config, subscriptionId) {
  return requireResponse(
    config,
    "POST",
    "/v1/subscriptionSubmissions",
    {
      data: {
        type: "subscriptionSubmissions",
        relationships: {
          subscription: { data: { type: "subscriptions", id: subscriptionId } },
        },
      },
    },
    [201]
  );
}

function summarizeReviewSubmissions(reviewSubmissions) {
  return reviewSubmissions.data.map((submission) => ({
    id: submission.id,
    ...submission.attributes,
    appStoreVersionForReviewId:
      submission.relationships?.appStoreVersionForReview?.data?.id || null,
    itemIds: submission.relationships?.items?.data?.map((item) => item.id) || [],
  }));
}

async function loadStatus(config, app, version) {
  const [build, attachedBuild, localizations, reviewDetail, reviewSubmissions, subscriptions, appInfos] =
    await Promise.all([
      getBuild(config, app.id),
      getRelationship(config, "appStoreVersions", version.id, "build"),
      getLocalizations(config, version.id),
      getReviewDetail(config, version.id),
      getReviewSubmissions(config, app.id),
      getSubscriptions(config, app.id),
      getAppInfos(config, app.id),
    ]);
  return {
    build,
    attachedBuild,
    localizations,
    reviewDetail,
    reviewSubmissions,
    subscriptions,
    appInfos,
  };
}

async function main() {
  const config = loadConfig();
  const app = await getApp(config);
  const version = await getVersion(config, app.id);
  if (!version) throw new Error(`No iOS App Store version ${versionString} found`);

  let status = await loadStatus(config, app, version);

  if (args.has("--attach-build")) {
    if (!status.build) throw new Error(`Build ${buildNumber} was not found`);
    await attachBuild(config, version.id, status.build.id);
  }

  if (args.has("--update-review-notes")) {
    if (!status.reviewDetail) throw new Error("No App Store review detail exists for this version");
    await updateReviewNotes(config, status.reviewDetail);
  }

  if (args.has("--update-metadata")) {
    const localization = status.localizations.find((item) => item.locale === "en-GB");
    if (!localization) throw new Error("No en-GB App Store version localization exists");
    await updateMetadata(config, localization);
  }

  if (args.has("--prepare-review")) {
    status = await loadStatus(config, app, version);
    const submittedReview = findSubmittedReviewSubmission(status.reviewSubmissions);
    if (!submittedReview) {
      let reviewSubmission = findDraftForVersion(status.reviewSubmissions, version.id);
      if (!reviewSubmission) {
        reviewSubmission =
          findReusableEmptyDraft(status.reviewSubmissions) ||
          (await createReviewSubmission(config, app.id));
      }
      if (reviewSubmission.relationships?.appStoreVersionForReview?.data?.id !== version.id) {
        await addVersionToReview(config, reviewSubmission.id, version.id);
      }
    }
  }

  if (args.has("--submit-review")) {
    status = await loadStatus(config, app, version);
    const submittedReview = findSubmittedReviewSubmission(status.reviewSubmissions);
    if (!submittedReview) {
      const reviewSubmission = findDraftForVersion(status.reviewSubmissions, version.id);
      if (!reviewSubmission) {
        throw new Error(
          "No review draft contains this app version; run --prepare-review and verify its items first"
        );
      }
      await submitReview(config, reviewSubmission.id);
    }
  }

  if (args.has("--submit-subscriptions")) {
    status = await loadStatus(config, app, version);
    const subscriptions = status.subscriptions.flatMap((group) => group.subscriptions);
    for (const subscription of subscriptions) {
      if (subscription.state === "READY_TO_SUBMIT") {
        await submitSubscription(config, subscription.id);
      }
    }
  }

  status = await loadStatus(config, app, version);
  console.log(
    JSON.stringify(
      {
        app: { id: app.id, ...app.attributes },
        requestedVersion: versionString,
        requestedBuild: buildNumber,
        version: { id: version.id, ...version.attributes },
        build: status.build ? { id: status.build.id, ...status.build.attributes } : null,
        attachedBuild: status.attachedBuild
          ? { id: status.attachedBuild.id, ...status.attachedBuild.attributes }
          : null,
        localizations: status.localizations,
        reviewDetail: status.reviewDetail
          ? { id: status.reviewDetail.id, ...status.reviewDetail.attributes }
          : null,
        subscriptions: status.subscriptions,
        appInfos: {
          data: status.appInfos.data?.map((item) => ({ id: item.id, ...item.attributes })),
          included: status.appInfos.included?.map((item) => ({
            type: item.type,
            id: item.id,
            ...item.attributes,
          })),
        },
        reviewSubmissions: summarizeReviewSubmissions(status.reviewSubmissions),
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
