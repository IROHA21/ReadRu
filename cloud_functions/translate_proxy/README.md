# Translate proxy Cloud Function

Moves the Yandex Translate API key out of the Flutter app and into a Yandex Cloud Function. Flutter calls this function; the function calls Yandex Translate on the app's behalf.

## Deploy

1. Yandex Cloud console → **Cloud Functions** → **Create function**.
2. Name it (e.g. `anyread-translate-proxy`).
3. Runtime: **Python 3.12** (or latest available).
4. Entry point: `index.handler`.
5. Paste in `index.py` as the function's source — no `requirements.txt` needed, it only uses the standard library.
6. Under **Environment variables**, add:
   - `YANDEX_API_KEY` — the real value currently in `lib/core/config/secrets.dart`.
   - `YANDEX_FOLDER_ID` — same, from `secrets.dart`.
   - `APP_SHARED_SECRET` (optional but recommended) — any string you make up. If set, the function rejects requests that don't send it back in an `X-App-Secret` header. This doesn't hide anything from a determined attacker (it still ships in the compiled app), but it keeps the function from being hit blind by anyone who stumbles on the URL and burning your Yandex quota/spend — the real API key still never leaves the function.
7. Timeout: bump to at least 10s (it makes one upstream HTTP call to Yandex).
8. Under the function's **Triggers**, add an **HTTP trigger** (or enable public invocation directly) — this gives you the callable URL, something like `https://functions.yandexcloud.net/<function-id>`.

## Test before touching Flutter

```bash
curl -X POST "https://functions.yandexcloud.net/<function-id>" \
  -H "Content-Type: application/json" \
  -H "X-App-Secret: <same value as APP_SHARED_SECRET, if you set one>" \
  -d '{"word":"привет","sourceLanguageCode":"ru","targetLanguageCode":"en"}'
```

Expect back: `{"translations":[{"text":"Hello"}]}` (Yandex's own response, passed through unchanged).

## Then wire up Flutter

Once you have the working URL, give it to me (and the shared secret if you set one) and I'll swap `reader_view.dart`'s `_translateWithYandex` over to call it instead of Yandex directly, and remove the real API key/folder id out of `secrets.dart` since the app won't need them anymore.
