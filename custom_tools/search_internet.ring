func search_internet(query)
    # هذه الأداة تستخدم read_url للوصول إلى خدمة بحث أو جلب معلومات
    # كمثال، سنقوم بتنسيق رابط بحث بسيط
    url = "https://www.google.com/search?q=" + query
    see "جاري البحث عن: " + query + nl
    return read_url(url)
