locals {
    content_types = {
        ".html" : "text/html",
        ".css"  : "text/css", 
        ".js"   : "text/javascript",
        ".png"  : "image/png",
        ".jpg"  : "image/jpg",
        ".svg"  : "image/svg",
        ".scss" : "text/css",
        ".eot"  : "application/vnd.ms-fontobject",
        ".ttf"  : "font/ttf",
        ".woff" : "font/woff",
        ".woff2": "font/woff2",
        ".pdf"  : "application/pdf"
    }
    
    s3_origin_id = "landing_page_access"
}


