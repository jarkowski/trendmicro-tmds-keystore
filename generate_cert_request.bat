@echo off
setlocal

:Start
cls
set FQDN=server.tm.example.com
set /p KEYSTORE_PASS=Passwort fuer den Keystore:
set /p KEYSTORE_PASS2=Passwort erneut eingeben:

if "%KEYSTORE_PASS%"=="%KEYSTORE_PASS2%" (
    echo OK
    goto Auswahl
) else (
    echo Fehler: Passwoerter stimmen nicht ueberein.
    echo.
    goto Ende
)


:Auswahl
echo.
echo Bitte waehlen:
echo   1) Neuen Keystore + CSR generieren
echo   2) CSR importieren
echo   3) Beenden
set /p CHOICE=Auswahl 1,2 oder 3, dann ENTER: 

if "%CHOICE%"=="1" goto NewKey
if "%CHOICE%"=="2" goto ImportCSR
if "%CHOICE%"=="2" goto Ende

echo.
echo Ungueltige Auswahl.
echo.
goto Ende


:NewKey
del java_keystore
del pkcs12_keystore
del certificate_request.csr
keytool -keypass %KEYSTORE_PASS% -storepass %KEYSTORE_PASS% -genkey -alias tomcat -keystore java_keystore -keyalg RSA -validity 3650 -keysize 4096 -dname "cn=%FQDN%, ou=IT, o=Trend Micro, l=Hamburg, s=Hamburg, c=CA"
if "%ERRORLEVEL%"=="0" (
    echo Keystore erstellt.
) else (
    echo Fehler beim erstellen des Keystores.
	goto Ende
)
keytool -srcstorepass %KEYSTORE_PASS% -deststorepass %KEYSTORE_PASS% -importkeystore -srckeystore java_keystore -destkeystore pkcs12_keystore -deststoretype pkcs12
if "%ERRORLEVEL%"=="0" (
    echo Keystore konvertiert.
) else (
    echo Fehler beim konvertieren des Keystores.
	goto Ende
)
keytool -storepass %KEYSTORE_PASS% -certreq -alias tomcat -keystore pkcs12_keystore -file certificate_request.csr -keyalg RSA -ext san=dns:%FQDN%

goto Ende


:ImportCSR

keytool -storepass %KEYSTORE_PASS% -import -alias tomcat -trustcacerts -file import_certificate.crt -keystore pkcs12_keystore
if "%ERRORLEVEL%"=="0" (
    echo CSR importiert.
) else (
    echo Fehler beim importieren des CSR.
	goto Ende
)
if exist .keystore del .keystore
copy pkcs12_keystore .keystore
goto Ende


:Ende
echo.
echo Ende
echo.
