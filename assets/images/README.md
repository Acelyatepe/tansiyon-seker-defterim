# Logo, ikon ve splash

Tek kaynak: `app_logo.png` (1254×1254). Kaynak dosya değiştirilmez; üretilen
PNG'lerde yalnızca orantılı ölçekleme ve ortalama kullanılır.

- Launcher: `android/app/src/main/res/mipmap-*/ic_launcher.png`.
- Adaptive icon: `mipmap-anydpi-v26/ic_launcher.xml`, krem zemin `#FBF6EE`,
  `%16` ön plan inset'i. Aynı kaynak PNG'den üretilen `ic_launcher_foreground`
  kullanılır. Kalp ve damla güvenli alanda kalır.
- Play Store: `release/store_assets/play_store_icon_512.png`, 512×512 PNG.
- Android 24–30 splash: yoğunluk başına 192dp kare `splash_logo.png`, merkezde.
- Android 31+ splash: 288dp krem karede ortalı 132dp logo; kaynak karenin tamamı
  192dp güvenli daireye sığar. `splash_icon.png` kullanılır.
- mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi için ölçekler 1/1.5/2/3/4'tür.

İkonları yeniden üretmek için `dart run flutter_launcher_icons` çalıştırın.
Splash ve Play PNG'leri kaynak logodan yeniden boyutlandırılmıştır; yeniden çizim,
renk değiştirme, kırpma veya animasyon uygulanmamıştır.
