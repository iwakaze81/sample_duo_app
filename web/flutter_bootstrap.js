{{flutter_js}}
{{flutter_build_config}}

// Flutter を <div id="app"> の中に描画し、上部の HTML ツールバーと共存させる。
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine({
      hostElement: document.querySelector('#app'),
    });
    await appRunner.runApp();
  },
});
