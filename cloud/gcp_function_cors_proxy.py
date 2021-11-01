"""Proxy for requests made to google rss feeds."""
import requests

RSS_URL_PART = "https://news.google.com/rss"


def forward_rss_request(request):
    """Responds to any HTTP request.
    Args:
        request (flask.Request): HTTP request object.
    Returns:
        The response text or any set of values that can be turned into a
        Response object using
        `make_response <http://flask.pocoo.org/docs/1.0/api/#flask.Flask.make_response>`.
    """

    # Set CORS headers for the preflight request.
    if request.method == 'OPTIONS':
        # Allows GET requests from any origin with the Content-Type
        # header and caches preflight response for an 3600s
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return ('', 204, headers)

    # Set CORS headers for the main request
    headers = {
        'Access-Control-Allow-Origin': '*'
    }

    request_json = request.get_json()
    url = ''
    print("*")
    print(request_json)
    print("-")
    print(request.args)
    if request.args and 'url' in request.args:
        url = request.args.get('url')
    elif request_json and 'url' in request_json:
        url = request_json['url']
    if not url:
        return ('No URL provided', 200, headers)

    if not url.startswith(RSS_URL_PART):
        return ('Invalid request domain', 200, headers)

    resp = requests.get(url)
    if not resp or resp.status_code != 200:
        return ('No data found', 200, headers)
    else:
        return (resp.text, 200, headers)
