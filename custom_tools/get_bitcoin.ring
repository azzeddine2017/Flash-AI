load "stdlib.ring"
load "jsonlib.ring"

func get_bitcoin()
    cCommand = 'curl -s "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd"'
    cOutput = systemcmd(cCommand)
    
    try
        aResp = json2list(cOutput)
        bMatched = false
        cPrice = ""
        # Safely parse since json2list returns list of lists e.g. [["bitcoin", [["usd", 64000]]]]
        for item in aResp
            if type(item) = "LIST" and len(item) = 2 and item[1] = "bitcoin"
                aCurrencies = item[2]
                for x in aCurrencies
                    if type(x) = "LIST" and len(x) = 2 and x[1] = "usd"
                        cPrice = "" + x[2]
                        bMatched = true
                    ok
                next
            ok
        next
        
        if bMatched
            return [:success = true, :message = "Current Bitcoin Price: $" + cPrice + " USD", :error = ""]
        else
            return [:success = false, :error = "خطأ: لم يتم العثور على السعر في الرد", :message = ""]
        ok
    catch
        return [:success = false, :error = "خطأ: تعذر الاتصال بخادم CoinGecko أو تحليل الرد.", :message = ""]
    done
ok


