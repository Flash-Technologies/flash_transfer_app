@echo off
setlocal enabledelayedexpansion

echo Adding language.json files to existing locale folders...
echo.

REM Create English language file
echo Creating assets\locales\en\language.json...
(
echo {
echo   "screen": {
echo     "title": "Language",
echo     "searchPlaceholder": "Search Language",
echo     "back": "Back"
echo   },
echo   "confirmation": {
echo     "title": "Language Change Confirmation",
echo     "message": "Are you sure you want to change the language to {languageName}? We are happy to assist you with that.",
echo     "subtitle": "This will update the entire app interface.",
echo     "buttons": {
echo       "yes": "Yes, Change Language",
echo       "no": "Cancel"
echo     },
echo     "success": "Language changed successfully to {languageName}",
echo     "loading": "Applying language changes...",
echo     "error": "Failed to change language. Please try again."
echo   },
echo   "languages": {
echo     "ar": "Arabic",
echo     "de": "German", 
echo     "en": "English",
echo     "es": "Spanish",
echo     "fr": "French",
echo     "hi": "Hindi",
echo     "nl": "Dutch",
echo     "pt": "Portuguese",
echo     "vi": "Vietnamese"
echo   },
echo   "errors": {
echo     "loadFailed": "Error loading languages",
echo     "noLanguagesFound": "No languages found",
echo     "tryAdjustingSearch": "Try adjusting your search query",
echo     "retry": "Retry"
echo   }
echo }
) > "assets\locales\en\language.json"

REM Create Arabic language file
echo Creating assets\locales\ar\language.json...
(
echo {
echo   "screen": {
echo     "title": "اللغة",
echo     "searchPlaceholder": "البحث عن لغة",
echo     "back": "رجوع"
echo   },
echo   "confirmation": {
echo     "title": "تأكيد تغيير اللغة",
echo     "message": "هل أنت متأكد من أنك تريد تغيير اللغة إلى {languageName}؟ نحن سعداء لمساعدتك في ذلك.",
echo     "subtitle": "سيؤدي هذا إلى تحديث واجهة التطبيق بالكامل.",
echo     "buttons": {
echo       "yes": "نعم، غيّر اللغة",
echo       "no": "إلغاء"
echo     },
echo     "success": "تم تغيير اللغة بنجاح إلى {languageName}",
echo     "loading": "جاري تطبيق تغييرات اللغة...",
echo     "error": "فشل في تغيير اللغة. يرجى المحاولة مرة أخرى."
echo   },
echo   "languages": {
echo     "ar": "العربية",
echo     "de": "الألمانية",
echo     "en": "الإنجليزية",
echo     "es": "الإسبانية",
echo     "fr": "الفرنسية",
echo     "hi": "الهندية",
echo     "nl": "الهولندية",
echo     "pt": "البرتغالية",
echo     "vi": "الفيتنامية"
echo   },
echo   "errors": {
echo     "loadFailed": "خطأ في تحميل اللغات",
echo     "noLanguagesFound": "لم يتم العثور على لغات",
echo     "tryAdjustingSearch": "حاول تعديل استعلام البحث",
echo     "retry": "إعادة المحاولة"
echo   }
echo }
) > "assets\locales\ar\language.json"

REM Create German language file
echo Creating assets\locales\de\language.json...
(
echo {
echo   "screen": {
echo     "title": "Sprache",
echo     "searchPlaceholder": "Sprache suchen",
echo     "back": "Zurück"
echo   },
echo   "confirmation": {
echo     "title": "Sprachänderung bestätigen",
echo     "message": "Sind Sie sicher, dass Sie die Sprache auf {languageName} ändern möchten? Wir helfen Ihnen gerne dabei.",
echo     "subtitle": "Dies wird die gesamte App-Oberfläche aktualisieren.",
echo     "buttons": {
echo       "yes": "Ja, Sprache ändern",
echo       "no": "Abbrechen"
echo     },
echo     "success": "Sprache erfolgreich auf {languageName} geändert",
echo     "loading": "Sprachänderungen werden angewendet...",
echo     "error": "Fehler beim Ändern der Sprache. Bitte versuchen Sie es erneut."
echo   },
echo   "languages": {
echo     "ar": "Arabisch",
echo     "de": "Deutsch",
echo     "en": "Englisch",
echo     "es": "Spanisch",
echo     "fr": "Französisch",
echo     "hi": "Hindi",
echo     "nl": "Niederländisch",
echo     "pt": "Portugiesisch",
echo     "vi": "Vietnamesisch"
echo   },
echo   "errors": {
echo     "loadFailed": "Fehler beim Laden der Sprachen",
echo     "noLanguagesFound": "Keine Sprachen gefunden",
echo     "tryAdjustingSearch": "Versuchen Sie, Ihre Suchanfrage anzupassen",
echo     "retry": "Wiederholen"
echo   }
echo }
) > "assets\locales\de\language.json"

REM Create Spanish language file
echo Creating assets\locales\es\language.json...
(
echo {
echo   "screen": {
echo     "title": "Idioma",
echo     "searchPlaceholder": "Buscar idioma",
echo     "back": "Atrás"
echo   },
echo   "confirmation": {
echo     "title": "Confirmación de cambio de idioma",
echo     "message": "¿Estás seguro de que quieres cambiar el idioma a {languageName}? Estamos encantados de ayudarte con eso.",
echo     "subtitle": "Esto actualizará toda la interfaz de la aplicación.",
echo     "buttons": {
echo       "yes": "Sí, cambiar idioma",
echo       "no": "Cancelar"
echo     },
echo     "success": "Idioma cambiado exitosamente a {languageName}",
echo     "loading": "Aplicando cambios de idioma...",
echo     "error": "Error al cambiar el idioma. Por favor, inténtalo de nuevo."
echo   },
echo   "languages": {
echo     "ar": "Árabe",
echo     "de": "Alemán",
echo     "en": "Inglés",
echo     "es": "Español",
echo     "fr": "Francés",
echo     "hi": "Hindi",
echo     "nl": "Holandés",
echo     "pt": "Portugués",
echo     "vi": "Vietnamita"
echo   },
echo   "errors": {
echo     "loadFailed": "Error al cargar idiomas",
echo     "noLanguagesFound": "No se encontraron idiomas",
echo     "tryAdjustingSearch": "Intenta ajustar tu consulta de búsqueda",
echo     "retry": "Reintentar"
echo   }
echo }
) > "assets\locales\es\language.json"

REM Create French language file
echo Creating assets\locales\fr\language.json...
(
echo {
echo   "screen": {
echo     "title": "Langue",
echo     "searchPlaceholder": "Rechercher une langue",
echo     "back": "Retour"
echo   },
echo   "confirmation": {
echo     "title": "Confirmation de changement de langue",
echo     "message": "Êtes-vous sûr de vouloir changer la langue en {languageName}? Nous sommes heureux de vous aider avec cela.",
echo     "subtitle": "Cela mettra à jour toute l'interface de l'application.",
echo     "buttons": {
echo       "yes": "Oui, changer la langue",
echo       "no": "Annuler"
echo     },
echo     "success": "Langue changée avec succès en {languageName}",
echo     "loading": "Application des changements de langue...",
echo     "error": "Échec du changement de langue. Veuillez réessayer."
echo   },
echo   "languages": {
echo     "ar": "Arabe",
echo     "de": "Allemand",
echo     "en": "Anglais",
echo     "es": "Espagnol",
echo     "fr": "Français",
echo     "hi": "Hindi",
echo     "nl": "Néerlandais",
echo     "pt": "Portugais",
echo     "vi": "Vietnamien"
echo   },
echo   "errors": {
echo     "loadFailed": "Erreur lors du chargement des langues",
echo     "noLanguagesFound": "Aucune langue trouvée",
echo     "tryAdjustingSearch": "Essayez d'ajuster votre requête de recherche",
echo     "retry": "Réessayer"
echo   }
echo }
) > "assets\locales\fr\language.json"

REM Create Hindi language file
echo Creating assets\locales\hi\language.json...
(
echo {
echo   "screen": {
echo     "title": "भाषा",
echo     "searchPlaceholder": "भाषा खोजें",
echo     "back": "वापस"
echo   },
echo   "confirmation": {
echo     "title": "भाषा परिवर्तन की पुष्टि",
echo     "message": "क्या आप वाकई भाषा को {languageName} में बदलना चाहते हैं? हम इसमें आपकी सहायता करने में खुश हैं।",
echo     "subtitle": "यह पूरे ऐप इंटरफेस को अपडेट कर देगा।",
echo     "buttons": {
echo       "yes": "हाँ, भाषा बदलें",
echo       "no": "रद्द करें"
echo     },
echo     "success": "भाषा सफलतापूर्वक {languageName} में बदल दी गई",
echo     "loading": "भाषा परिवर्तन लागू किए जा रहे हैं...",
echo     "error": "भाषा बदलने में असफल। कृपया पुनः प्रयास करें।"
echo   },
echo   "languages": {
echo     "ar": "अरबी",
echo     "de": "जर्मन",
echo     "en": "अंग्रेजी",
echo     "es": "स्पेनिश",
echo     "fr": "फ्रेंच",
echo     "hi": "हिंदी",
echo     "nl": "डच",
echo     "pt": "पुर्तगाली",
echo     "vi": "वियतनामी"
echo   },
echo   "errors": {
echo     "loadFailed": "भाषाएं लोड करने में त्रुटि",
echo     "noLanguagesFound": "कोई भाषा नहीं मिली",
echo     "tryAdjustingSearch": "अपनी खोज क्वेरी को समायोजित करने का प्रयास करें",
echo     "retry": "पुनः प्रयास करें"
echo   }
echo }
) > "assets\locales\hi\language.json"

REM Create Dutch language file
echo Creating assets\locales\nl\language.json...
(
echo {
echo   "screen": {
echo     "title": "Taal",
echo     "searchPlaceholder": "Taal zoeken",
echo     "back": "Terug"
echo   },
echo   "confirmation": {
echo     "title": "Taalwijziging bevestigen",
echo     "message": "Weet je zeker dat je de taal wilt wijzigen naar {languageName}? We helpen je daar graag bij.",
echo     "subtitle": "Dit zal de hele app-interface bijwerken.",
echo     "buttons": {
echo       "yes": "Ja, verander taal",
echo       "no": "Annuleren"
echo     },
echo     "success": "Taal succesvol gewijzigd naar {languageName}",
echo     "loading": "Taalwijzigingen worden toegepast...",
echo     "error": "Taal wijzigen mislukt. Probeer het opnieuw."
echo   },
echo   "languages": {
echo     "ar": "Arabisch",
echo     "de": "Duits",
echo     "en": "Engels",
echo     "es": "Spaans",
echo     "fr": "Frans",
echo     "hi": "Hindi",
echo     "nl": "Nederlands",
echo     "pt": "Portugees",
echo     "vi": "Vietnamees"
echo   },
echo   "errors": {
echo     "loadFailed": "Fout bij het laden van talen",
echo     "noLanguagesFound": "Geen talen gevonden",
echo     "tryAdjustingSearch": "Probeer je zoekopdracht aan te passen",
echo     "retry": "Opnieuw proberen"
echo   }
echo }
) > "assets\locales\nl\language.json"

REM Create Portuguese language file
echo Creating assets\locales\pt\language.json...
(
echo {
echo   "screen": {
echo     "title": "Idioma",
echo     "searchPlaceholder": "Pesquisar idioma",
echo     "back": "Voltar"
echo   },
echo   "confirmation": {
echo     "title": "Confirmação de mudança de idioma",
echo     "message": "Tem certeza de que deseja alterar o idioma para {languageName}? Ficamos felizes em ajudá-lo com isso.",
echo     "subtitle": "Isso atualizará toda a interface do aplicativo.",
echo     "buttons": {
echo       "yes": "Sim, alterar idioma",
echo       "no": "Cancelar"
echo     },
echo     "success": "Idioma alterado com sucesso para {languageName}",
echo     "loading": "Aplicando alterações de idioma...",
echo     "error": "Falha ao alterar idioma. Tente novamente."
echo   },
echo   "languages": {
echo     "ar": "Árabe",
echo     "de": "Alemão",
echo     "en": "Inglês",
echo     "es": "Espanhol",
echo     "fr": "Francês",
echo     "hi": "Hindi",
echo     "nl": "Holandês",
echo     "pt": "Português",
echo     "vi": "Vietnamita"
echo   },
echo   "errors": {
echo     "loadFailed": "Erro ao carregar idiomas",
echo     "noLanguagesFound": "Nenhum idioma encontrado",
echo     "tryAdjustingSearch": "Tente ajustar sua consulta de pesquisa",
echo     "retry": "Tentar novamente"
echo   }
echo }
) > "assets\locales\pt\language.json"

REM Create Vietnamese language file
echo Creating assets\locales\vi\language.json...
(
echo {
echo   "screen": {
echo     "title": "Ngôn ngữ",
echo     "searchPlaceholder": "Tìm kiếm ngôn ngữ",
echo     "back": "Quay lại"
echo   },
echo   "confirmation": {
echo     "title": "Xác nhận thay đổi ngôn ngữ",
echo     "message": "Bạn có chắc chắn muốn thay đổi ngôn ngữ thành {languageName} không? Chúng tôi rất vui được hỗ trợ bạn điều đó.",
echo     "subtitle": "Điều này sẽ cập nhật toàn bộ giao diện ứng dụng.",
echo     "buttons": {
echo       "yes": "Có, thay đổi ngôn ngữ",
echo       "no": "Hủy bỏ"
echo     },
echo     "success": "Đã thay đổi ngôn ngữ thành công thành {languageName}",
echo     "loading": "Đang áp dụng các thay đổi ngôn ngữ...",
echo     "error": "Không thể thay đổi ngôn ngữ. Vui lòng thử lại."
echo   },
echo   "languages": {
echo     "ar": "Tiếng Ả Rập",
echo     "de": "Tiếng Đức",
echo     "en": "Tiếng Anh",
echo     "es": "Tiếng Tây Ban Nha",
echo     "fr": "Tiếng Pháp",
echo     "hi": "Tiếng Hindi",
echo     "nl": "Tiếng Hà Lan",
echo     "pt": "Tiếng Bồ Đào Nha",
echo     "vi": "Tiếng Việt"
echo   },
echo   "errors": {
echo     "loadFailed": "Lỗi khi tải ngôn ngữ",
echo     "noLanguagesFound": "Không tìm thấy ngôn ngữ nào",
echo     "tryAdjustingSearch": "Hãy thử điều chỉnh truy vấn tìm kiếm của bạn",
echo     "retry": "Thử lại"
echo   }
echo }
) > "assets\locales\vi\language.json"

echo.
echo ================================
echo All language.json files added successfully!
echo ================================
echo.
echo Files created:
echo - assets\locales\en\language.json
echo - assets\locales\ar\language.json
echo - assets\locales\de\language.json
echo - assets\locales\es\language.json
echo - assets\locales\fr\language.json
echo - assets\locales\hi\language.json
echo - assets\locales\nl\language.json
echo - assets\locales\pt\language.json
echo - assets\locales\vi\language.json
echo.
echo Script execution completed!
pause