# Cinny
"A Matrix client focusing primarily on simple, elegant and secure interface. The main goal is to have an instant messaging application that is easy on people and has a modern touch."

[Cinny about Cinny](https://github.com/cinnyapp/cinny)

## Cinny UT

This is Cinny packaged for Ubuntu Touch with content hub integration and other changes to make it run as native matrix client. The original work has been done by @nitanmarcel. Many thanks for that! Now the app is maintained by Danfro.

Cinny does not only allow to let you have matrix messages on your UT device. With bridges you can have many more messages available like Signal or Slack. Please check the internet for available matrix bridges.

## License

[Cinny](https://github.com/cinnyapp/cinny) source package licensed under [GNU AFFERO GENERAL PUBLIC LICENSE Version 3](https://github.com/cinnyapp/cinny/blob/dev/LICENSE) (c) Ajay Bura (ajbura) and contributors.

[Graphics](/svg/) by Ajay Bura (ajbura) licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)  (c) by Ajay Bura (ajbura).

Click packaging was originally done by [Marcel Alexandru Nitan](https://github.com/nitanmarcel/cinny-click-packaging) [GPLv3](https://github.com/nitanmarcel/cinny-click-packaging/blob/dev/LICENSE) (C) 2022  Marcel Alexandru Nitan. Thanks to his work we have this great app available on UT.

The forked app in this repository maintained by me (Danfro).

[![OpenStore](https://open-store.io/badges/en_US.png)](https://open-store.io/app/cinny.danfro)

## Building the app

1. Install [Clickable](https://clickable-ut.dev/en/dev/index.html)
2. Get a local copy of this repository with `git clone --recurse-submodules git@github.com:Danfro/cinny-ut.git`
3. Change into the cinny click packaging folder
4. Attach an Ubuntu Touch device via usb to your machine
4. Run `clickable --clean` from the root folder of this repository to build and deploy the app on your attached device, or run `clickable desktop` to test the app on desktop. You can run `clickable log` for debugging information. In my experience `clickable --dirty` doesn't work well and brings funny errors in ciny.
5. When only modifying the QML/UT part of the app, you can avoid rebuilding Cinny every time you build and run the app by temporarily commenting out the line `prebuild: "bash ${ROOT}/prebuild.sh"` in `clickable.yaml`

The build process does download and install
- nvm
- node
- cinny source

Doing all three steps every time cinny-ut is build is quite cumbersome. To avoid this, the `prebuild.sh` script has been designed to allow using locally present copies of the three.

- `nvm` needs to be installed into the `cinny-ut/nvm` subfolder, get it [here](https://github.com/nvm-sh/nvm?tab=readme-ov-file#installing-and-updating), since `nvm` is only used to install node, it doesn't need to be installed when node is installed locally, update with the curl command given on their github page
- `nodejs` (aka `npm`) needs to be installed into the `cinny-ut/npm` subfolder, get it [here](https://nodejs.org/en/download), generally you need the *node_x64* architecture when downloading a prebuild package, update with `nvm install 22.15.1`
- cinny source needs to be in the `cinny-ut/cinny` subfolder, this can be cloned from their github with `git clone https://github.com/cinnyapp/cinny cinny --recurse-submodules --depth=1 --branch="v4.7.0"`

## Patches

For UT integration several patches are applied. Those are located in the `/patches` folder. Please see the [patch description](/patches/patch_description.md) for details.

When Cinny is build, first a fresh copy of Cinny with the version specified in [prebuild.sh](/prebuild.sh) is downloaded from the originating repository. So if we need to apply changes, we need to use patches, that will be applied after the code has been downloaded.

Before the click packaging, in [prebuild.sh](/prebuild.sh) the function `apply_patches ()` cycles through all available `.patch` files and applies the changes. Patches use the `git diff` magic to create patches and to apply those changes.

To create a patch...
- enter the folder of the git repository (for Cinny the /cinny subfolder) with `cd cinny`
- make sure only the changes are present, that want to go into one patch, discard all other changes OR run `git diff` specifying a single file
- use `git diff > file.patch` to create a patch file of all present changes
- for the diff of a single file run `git diff -- ./src/client/state/cons.js -p > ../patches/cons.patch`
- `cd ..` back into the cinny packaging folder
- after each build leave the cinny subfolder, otherwise git will not pick up changes
- move the patch file from the cinny folder to the patches folder
- combined command (edit patch file name): 

  `cd cinny && git diff > ../patches/0006-Download-media-using-qml-backend.patch && cd ..`

- the `git apply` command is then used in [prebuild.sh](/prebuild.sh) to apply the diff patches
