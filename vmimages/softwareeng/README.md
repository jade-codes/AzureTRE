# Software Engineering VM Image

The following terraform configuration is used to deploy a VM Image template for software engineering.

The template can be deployed using the `make vm-softwareeng-deploy` command.

Once deployed the required version of the image can then be built.  Before running the build command ensure that the following files are present in the stsft<TRE_ID> storage account:

|Name|Source|Destination|
|---|---|---|
|VS Code| [https://update.code.visualstudio.com/latest/win32-x64/stable](https://update.code.visualstudio.com/latest/win32-x64/stable) | `softwareeng/vscode_installer.exe`|
| Git for Windows | [https://github.com/git-for-windows/git/releases/download/v2.50.1.windows.1/Git-2.50.1-64-bit.exe](https://github.com/git-for-windows/git/releases/download/v2.50.1.windows.1/Git-2.50.1-64-bit.exe) | `softwareeng/git_installer.exe`|
| Podman | [https://github.com/containers/podman/releases/download/v5.2.2/podman-5.2.2-setup.exe](https://github.com/containers/podman/releases/download/v5.2.2/podman-5.2.2-setup.exe) | `softwareeng/podman_installer.exe`|
| Podman WSL Image | [https://github.com/containers/podman-machine-wsl-os/releases/download/v20250206061445/5.3-rootfs-amd64.tar.zst](https://github.com/containers/podman-machine-wsl-os/releases/download/v20250206061445/5.3-rootfs-amd64.tar.zst) | `softwareeng/5.3-rootfs-amd64.tar.zst`|


The files can be downloaded using the following make command `make vm-softwareeng-fetch-dependencies`.  

Once the files are in place, the image can be built by finding the image template in the Azure portal and selecting the "Start Build" option.  Once complete the image will be shown in the Azure Compute Gallery under the `softwareengvmi` image definition.

The guacamole windows VM user resource has been updated to offer the software engineering image as an option.  The image can be selected when creating a new VM in the TRE interface.

