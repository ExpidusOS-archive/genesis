'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"canvaskit/skwasm.worker.js": "bfb704a6c714a75da9ef320991e88b03",
"canvaskit/skwasm.js": "5d4f9263ec93efeb022bb14a3881d240",
"canvaskit/canvaskit.wasm": "9251bb81ae8464c4df3b072f84aa969b",
"canvaskit/canvaskit.js.symbols": "74a84c23f5ada42fe063514c587968c6",
"canvaskit/skwasm.js.symbols": "c3c05bd50bdf59da8626bbe446ce65a3",
"canvaskit/skwasm.wasm": "4051bfc27ba29bf420d17aa0c3a98bce",
"canvaskit/canvaskit.js": "738255d00768497e86aa4ca510cce1e1",
"canvaskit/chromium/canvaskit.wasm": "399e2344480862e2dfa26f12fa5891d7",
"canvaskit/chromium/canvaskit.js.symbols": "ee7e331f7f5bbf5ec937737542112372",
"canvaskit/chromium/canvaskit.js": "901bb9e28fac643b7da75ecfd3339f3f",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"manifest.json": "4b4f837faf67a3018fa167344736e9bb",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter_bootstrap.js": "305e384462b4d14ec51ce38516bffa63",
"version.json": "78899602b671047dd3076815cbdbc72f",
"libtokyo/data/themes/storm.json": "bd04389582f1013e19a4c6c4fb88201e",
"libtokyo/data/themes/day.json": "eb5e4bb1b8c537a40f2c0ac01519e381",
"libtokyo/data/themes/moon.json": "94a4f9eae4951c6c14c7a9a7d93130e0",
"libtokyo/data/themes/night.json": "2e07c72e669cc6fd9afc702a030459d8",
"index.html": "ebb2f4bd037efb5e526968c4aba022ea",
"/": "ebb2f4bd037efb5e526968c4aba022ea",
"main.dart.js": "f633c3b1c51c3ec4088f5c45977746cf",
"assets/AssetManifest.json": "f628ce05ce52e2fe3a8947ada805922a",
"assets/packages/libtokyo/data/themes/storm.json": "bd04389582f1013e19a4c6c4fb88201e",
"assets/packages/libtokyo/data/themes/day.json": "eb5e4bb1b8c537a40f2c0ac01519e381",
"assets/packages/libtokyo/data/themes/moon.json": "94a4f9eae4951c6c14c7a9a7d93130e0",
"assets/packages/libtokyo/data/themes/night.json": "2e07c72e669cc6fd9afc702a030459d8",
"assets/packages/font_awesome_flutter/lib/fonts/fa-regular-400.ttf": "9b226da64f0cf35a7da4852235c468c6",
"assets/packages/font_awesome_flutter/lib/fonts/fa-brands-400.ttf": "17ee8e30dde24e349e70ffcdc0073fb0",
"assets/packages/font_awesome_flutter/lib/fonts/fa-solid-900.ttf": "28a84abdb3b7f24ab8ed4e169a54a2a7",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin.json": "b69a830ff57ffe79b3ed619339e9438a",
"assets/assets/wallpaper/desktop/dark-sand.jpg": "682331fecc91f23241723a5460823a15",
"assets/assets/wallpaper/desktop/mountains.jpg": "06d7f4f40b75ed40c85c2b710f057a73",
"assets/assets/wallpaper/desktop/default.jpg": "ca5ee3d0fcab9db663c17ad11c2cfa1a",
"assets/assets/wallpaper/desktop/lake.jpg": "f066d2ad25c0201c7386f80330849c90",
"assets/assets/wallpaper/desktop/tokyo-road.jpg": "0d241b8130738690b8da2a798149d42f",
"assets/assets/wallpaper/mobile/road-flash.jpg": "6cbe3f32ae6f65cf1a5c6e497ab80859",
"assets/assets/wallpaper/mobile/default.jpg": "baa4f35e6660e0f66524b917a46dc607",
"assets/assets/wallpaper/mobile/neon-tokyo.jpg": "ef68d96a9531e6b700cda3b0a2234062",
"assets/assets/google_fonts/Saira-Medium.ttf": "8800a727f9f9a495a861453675aee041",
"assets/assets/google_fonts/Saira-BlackItalic.ttf": "071deeb3cef4dff318f62f497fe4cfce",
"assets/assets/google_fonts/Saira-ThinItalic.ttf": "6de15a891f45d8ed14f302fed3aa5d34",
"assets/assets/google_fonts/ZenMaruGothic-Bold.ttf": "058f351e5a896a306665b679447d2e6a",
"assets/assets/google_fonts/Saira-Light.ttf": "1cea46009ade432af3490c128f62e29d",
"assets/assets/google_fonts/Saira-MediumItalic.ttf": "d90505164b47905688c395114883559c",
"assets/assets/google_fonts/Saira-LightItalic.ttf": "74c9f5dbe0cb5eacb8cc41321755fbbf",
"assets/assets/google_fonts/Saira-SemiBoldItalic.ttf": "6940214ef18a1b7344ac580bc91ef7c8",
"assets/assets/google_fonts/ZenMaruGothic-Regular.ttf": "f813d4953981ab82a6bf3a80c6343e13",
"assets/assets/google_fonts/Saira-ExtraLight.ttf": "e05f928a47b947cdf04bbd15e6cc8dba",
"assets/assets/google_fonts/ZenMaruGothic-Medium.ttf": "bf8e87f5faf58c8398e9dea92dcd13af",
"assets/assets/google_fonts/Saira-Black.ttf": "6bde89c2518d6a254cbea7e1876586fe",
"assets/assets/google_fonts/Saira-Bold.ttf": "43b1b372d7feb4d1df845f799700eeb5",
"assets/assets/google_fonts/Saira-SemiBold.ttf": "f800ac13efb6120e7d852ce8b1b4a5a7",
"assets/assets/google_fonts/ZenMaruGothic-Light.ttf": "ada78ce0a74d69b6b7bc922b313f3e10",
"assets/assets/google_fonts/Saira-Thin.ttf": "995b72130d24e4b61cdd38a60331abe4",
"assets/assets/google_fonts/ZenMaruGothic-Black.ttf": "cf2422ff28ff6d02d9883b5db510e091",
"assets/assets/google_fonts/Saira-ExtraBoldItalic.ttf": "09a357ca9617ef054e317900d76729d8",
"assets/assets/google_fonts/Saira-Italic.ttf": "aaa60384916d08c1372b89a8c7f5eda3",
"assets/assets/google_fonts/OFL.txt": "46f5b8636a4af3245d2cecc4f92b9a58",
"assets/assets/google_fonts/Saira-ExtraLightItalic.ttf": "88bedf3fe747be7ee67e6272357e7d3d",
"assets/assets/google_fonts/Saira-BoldItalic.ttf": "23c632776a117350a248eaf78c8f8670",
"assets/assets/google_fonts/Saira-ExtraBold.ttf": "82d4d77cbfe7ef39bc3663cabf208ac8",
"assets/assets/google_fonts/Saira-Regular.ttf": "342d9d9fdfc203910d1f55470ef027f4",
"assets/NOTICES": "cfa1a16e59805893b278ad9150b8a916",
"assets/AssetManifest.bin": "188e0cf43d2d58c39053c9f2212f84b1",
"assets/FontManifest.json": "13a826883971e5493399d93d37ea8c55",
"flutter.js": "383e55f7f3cce5be08fcf1f3881f585c",
"CNAME": "b9f5ad4a71f27e2e9a7d74383df62bc1"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
