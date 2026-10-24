# study-ios

Study Together (Capacitor web app + native iOS plugins). Pushing to `main` runs the
"Build unsigned IPA" workflow and uploads `StudyTogether-ipa`.

## Updates (built into the app)
Open the app as `zezo` > Admin tab > "Send app update to everyone". Fill in a title, message and
install link (leave the link empty to use the default GitHub .ipa link) and tap Send. Everyone with
the iPhone app sees an Update page; the Update button opens the link in Safari.
Firebase rules must allow reading `app/update` for everyone and writing it for the admin.

## Screen Time
Needs Apple's Family Controls entitlement on the account that signs the app (see notes).
