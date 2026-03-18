自行打包的 [Microsoft Edit](https://github.com/microsoft/edit)，适用于基于 Debian 的发行版。

Self-packaged [Microsoft Edit](https://github.com/microsoft/edit), suitable for Debian-based distro.


## Usage/用法

### 直接下载 .deb 文件

直接从 [Releases](https://github.com/wcbing-build/msedit-debs/releases) 下载 .deb 文件。

### 添加 apt 仓库

```sh
echo "Types: deb
URIs: https://github.com/wcbing-build/msedit-debs/releases/latest/download/
Suites: ./
Trusted: yes" | sudo tee /etc/apt/sources.list.d/msedit.sources
sudo apt update
sudo apt install msedit
```