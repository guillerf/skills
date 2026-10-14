---
name: estetix-3d-simulator
description: "Create 3D reconstructions or work in Estetix, the Crisalix surgeons' simulator; route staging instances and use photo and measurement defaults."
---

# Estetix 3D Simulator

## Procedure

1. **Choose the requested staging instance.** Interpret `staging1`, `estetix1`, and `Crisalix3D-1` as instance 1, and likewise for instances 2–6. If no instance is specified, use Crisalix3D (the unnumbered instance). Verify the browser hostname before changing patient data.

   | App | URL |
   | --- | --- |
   | Crisalix3D (default) | https://estetix-staging.crisalix.com/ |
   | Crisalix3D-1 | https://estetix1-staging.crisalix.com/ |
   | Crisalix3D-2 | https://estetix2-staging.crisalix.com/ |
   | Crisalix3D-3 | https://estetix3-staging.crisalix.com/ |
   | Crisalix3D-4 | https://estetix4-staging.crisalix.com/ |
   | Crisalix3D-5 | https://estetix5-staging.crisalix.com/ |
   | Crisalix3D-6 | https://estetix6-staging.crisalix.com/ |

2. **Establish authenticated access.** Reuse the persistent browser profile and an existing matching tab. If sign-in is required, use https://sso-staging.crisalix.com/ and the account's configured credential store, then open the selected Estetix app. Use the existing host-local login helper when available; keep passwords out of snapshots, logs, repository files, and tool output. On macOS the configured Keychain service is `openclaw.crisalix.staging`; obtain the account identifier from local configuration. Report login, locked-Keychain, or 2FA blockers accurately. Continue when the selected app displays the expected signed-in account.

3. **Resolve the task and photo inputs.** For an existing-patient task, locate the requested patient and perform the requested operation rather than creating a new patient. For a new reconstruction, determine the family and subtype from the request and the table below. Use an explicitly provided measurement instead of its default; otherwise use the listed default without asking again. Inspect source photos visually and verify that they cover every required view of the same patient. Exclude extra views rather than duplicating or inventing missing ones. Resolve a missing required view or ambiguous subtype before submitting.

   | Family | UI subtype / aliases | Required views | Default measurement | Approximate processing |
   | --- | --- | --- | --- | --- |
   | Breast | Breast | Front, left 45°, right 45° (3 photos) | Nipple-to-nipple: 21 cm | 30 seconds |
   | Face | Higher speed / fast full head | Left 45°, front, right 45° (3 photos) | Patient pupillary distance: 6 cm | 1 minute |
   | Face | Higher accuracy / full head | Left, left 45°, front, right 45°, right, below (6 photos) | Patient pupillary distance: 6 cm | 2 minutes |
   | Body | Body | Front, left, right, back (4 photos) | Hip circumference: 85 cm | 30 seconds |
   | Body | Full body | Front, left, right, back (4 photos) | Nipple-to-nipple: 21 cm | 1 minute |

   These durations are estimates, not completion guarantees. Left/right labels follow the application's view convention; compare visible reference illustrations or recognized photo labels rather than inferring slot assignment from filenames.

4. **Create and configure the patient.** Click **New patient**. Set **Patient's Name or ID** exactly as requested; otherwise retain the generated name. Leave an unspecified patient email blank. Select **Face**, **Breast**, or **Body**, then **Add patient**. Record the resulting patient URL/ID immediately so interrupted work resumes on that patient rather than creating a duplicate. Choose the requested subtype and enter its measurement in the displayed units. Verify the patient name, subtype, expected photo count, and measurement on the current page.

5. **Upload and check photos.** Upload the required original image files through **Select photos** or the page's file input. On the observed Face uploader, the multiple-file input is `#photos_field-js`; inspect the current DOM before reusing that selector. With OpenClaw browser uploads, stage files under its supported temporary uploads directory first. Take a fresh snapshot after uploads and after any classification or confirmation modal. For Face, the uploader states that photo order is not important; inspect every thumbnail to verify the required views. Slot captions alone are not evidence of automatic view recognition; where possible, upload in the displayed view order for a clear visual check. Confirm all required photos are accepted, the chosen subtype remains selected, the measurement is retained, and **Create 3D** is enabled.

6. **Submit once and notify immediately.** Click **Create 3D** once for an authorized creation request. Confirm the page accepted the request and entered processing, or report the visible validation error. Tell the user promptly that creation was submitted, with the instance, patient name/link, subtype, and approximate duration. Do not describe a submitted reconstruction as completed. On a timeout or interrupted response, inspect the existing patient's state before considering any retry.

7. **Verify the requested end state.** If the task includes waiting for completion, inspect processing state at an appropriate interval without repeatedly clicking **Create 3D**. Finish when the model/simulator is available or a concrete error is shown, and report the observed result and patient link. If the user only asked to be notified at submission, finish after the submission acknowledgment and leave the patient page available for follow-up.
