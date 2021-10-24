import requests

sess = requests.session()
function_url = "https://us-central1-mcprep-cloud.cloudfunctions.net/dcg-know-news-cors-proxy"
rss_url = "https://news.google.com/rss/search?q=game%20engine&hl=en-US&gl=US&ceid=US:en"

#with sess.get(url, headers=None, stream=True) as resp:
#     data = resp.text
resp = requests.post(function_url, params={"url": rss_url})

if not resp or resp.status_code != 200:
    print("Error, failed to fetch data")
    print(resp)
else:
    data = resp.text # Raw text
    print(data[:150])

# Now test the actual url itself (ie a test of the cloud function code)

#resp = requests.get(rss_url)
#print(resp.text[:50]