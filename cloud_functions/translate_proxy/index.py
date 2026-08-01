"""Yandex Cloud Function: proxies the app's word-translation requests to
Yandex Translate v2, so the real API key/folder id never ship inside the
Flutter app - they live only in this function's environment variables.

Request body (from Flutter, unchanged from the old direct-call shape):
    {"word": "...", "sourceLanguageCode": "ru", "targetLanguageCode": "en"}

Response body (passed through as-is from Yandex, so Flutter's existing
`decoded['translations'][0]['text']` parsing doesn't need to change):
    {"translations": [{"text": "..."}]}
"""

import json
import os
import urllib.error
import urllib.request

YANDEX_TRANSLATE_URL = "https://translate.api.cloud.yandex.net/translate/v2/translate"


def handler(event, context):
    try:
        body = json.loads(event.get("body") or "{}")
    except ValueError:
        return _response(400, {"error": "invalid JSON body"})

    word = body.get("word")
    source = body.get("sourceLanguageCode")
    target = body.get("targetLanguageCode")
    if not word or not source or not target:
        return _response(400, {"error": "word, sourceLanguageCode and targetLanguageCode are required"})

    # Optional lightweight gate: if APP_SHARED_SECRET is set as an env var,
    # require the same value in an X-App-Secret header. This doesn't
    # protect a determined attacker (the header value still ships in the
    # app), but it stops the function's public URL from being hit blind by
    # anyone who finds it - keeps translate spend/quota from being drained
    # by strangers, separate from the real Yandex key staying server-side.
    expected_secret = os.environ.get("APP_SHARED_SECRET")
    if expected_secret:
        headers = event.get("headers") or {}
        provided_secret = headers.get("X-App-Secret") or headers.get("x-app-secret")
        if provided_secret != expected_secret:
            return _response(401, {"error": "unauthorized"})

    api_key = os.environ["YANDEX_API_KEY"]
    folder_id = os.environ["YANDEX_FOLDER_ID"]

    payload = json.dumps(
        {
            "folderId": folder_id,
            "texts": [word],
            "sourceLanguageCode": source,
            "targetLanguageCode": target,
        }
    ).encode("utf-8")

    request = urllib.request.Request(
        YANDEX_TRANSLATE_URL,
        data=payload,
        method="POST",
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Api-Key {api_key}",
        },
    )

    try:
        with urllib.request.urlopen(request, timeout=10) as upstream:
            upstream_body = json.loads(upstream.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        return _response(error.code, {"error": "yandex translate request failed"})
    except urllib.error.URLError:
        return _response(502, {"error": "could not reach yandex translate"})

    return _response(200, upstream_body)


def _response(status_code, payload):
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(payload),
    }
