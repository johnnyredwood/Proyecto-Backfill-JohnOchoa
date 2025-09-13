import requests, os, time

@data_loader
def load_clients(**kwargs):

    client_id = os.environ.get("QBO_CLIENT_ID")
    client_secret = os.environ.get("QBO_CLIENT_SECRET")
    refresh_token = os.environ.get("QBO_REFRESH_TOKEN")
    realm_id = os.environ.get("QBO_REALM_ID")
    token_url = "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer"

    resp = requests.post(
        token_url,
        data={
            "grant_type": "refresh_token",
            "refresh_token": refresh_token
        },
        auth=(client_id, client_secret)
    )
    resp.raise_for_status()
    access_token = resp.json()["access_token"]

    base_url = f"https://sandbox-quickbooks.api.intuit.com/v3/company/{realm_id}/query"
    results = []

    start_position = 1
    page_size = kwargs.get('page_size', 100)

    while True:
        query = f"SELECT * FROM Customer STARTPOSITION {start_position} MAXRESULTS {page_size}"
        headers = {"Authorization": f"Bearer {access_token}", "Accept": "application/json"}

        r = requests.get(base_url, headers=headers, params={"query": query}, timeout=30)
        r.raise_for_status()
        data = r.json().get("QueryResponse", {}).get("Customer", [])

        if not data:
            break

        results.extend(data)

        if len(data) < page_size:
            break

        start_position += len(data)

    return results