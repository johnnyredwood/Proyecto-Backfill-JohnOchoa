from datetime import datetime

@transformer
def add_metadata(data, **kwargs):
    for row in data:
        row["ingested_at_utc"] = datetime.utcnow().isoformat()
        row["extract_window_start_utc"] = kwargs['fecha_inicio']
        row["extract_window_end_utc"] = kwargs['fecha_fin']
        row["page_number"] = kwargs['page_number']
        row["page_size"] = kwargs['page_size']
        row["request_payload"] = {}
    return data