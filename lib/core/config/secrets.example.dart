// Copy this file to secrets.dart (same folder) and fill in your own values.
// secrets.dart is gitignored - never commit real keys there.
//
// The Yandex Translate API key/folder id moved server-side into the
// translate_proxy Cloud Function's environment variables (see
// cloud_functions/translate_proxy/) - the app no longer holds them directly.

// Must match APP_SHARED_SECRET in the Cloud Function's environment
// variables exactly - any string works, it's not a real credential.
const appSharedSecret = '';
