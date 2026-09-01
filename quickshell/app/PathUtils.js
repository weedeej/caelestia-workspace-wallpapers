.pragma library

function fileUrl(path) {
    if (!path)
        return ""
    return "file://" + encodeURIComponent(String(path)).replace(/%2F/gi, "/")
}

function basename(path) {
    const parts = String(path || "").split("/")
    return parts[parts.length - 1]
}
