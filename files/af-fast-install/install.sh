#/bin/bash
# 从https://static.itedev.com/files/install-package.tar.gz下载安装包
wget https://static.itedev.com/files/af-fast-install/package.tar.gz
# 解压安装包
tar -zxvf install-package.tar.gz
# 进入安装包目录
cd install-package
# 加权
chmod +x installer/*
# 执行安装脚本
./installer/easytier.sh
./installer/dependence.sh

