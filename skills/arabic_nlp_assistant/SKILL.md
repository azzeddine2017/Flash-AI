---
name: arabic_nlp_assistant
description: إرشادات وتقنيات متقدمة لمعالجة النصوص العربية واللغات الطبيعية (NLP) في تطبيقات وبرمجيات لغة Ring.
---

# Arabic NLP Assistant Skill

## Overview
This skill provides guidelines for handling Arabic text processing, encoding (UTF-8), tokenization, and string manipulation within Ring programming language applications.

## Best Practices
1. **UTF-8 Encoding:** Always ensure that source files and input/output streams are handled in UTF-8 to correctly process Arabic characters (حروف الأبجدية العربية).
2. **String Functions:** Utilize Ring's built-in string functions (`substr`, `left`, `right`, `lower`, `upper`) keeping in mind that Arabic letters take multiple bytes in UTF-8 depending on implementation, but Ring handles characters seamlessly in standard string buffers.
3. **Text Normalization:** Implement helper functions to normalize Arabic Hamza variations (أ, إ, آ -> ا) and remove Tashkeel (الحركات) when performing search or indexing tasks.
