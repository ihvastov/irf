#!/bin/bash

fmt=`tput setaf 45`
end="\e[0m\n"
err="\e[31m"
scss="\e[32m"

echo -e "${fmt}Checking parameters / Проверяем параметры${end}" && sleep 1
    nGR=${#IRONFISH_GRAFFITI}
    nWL=${#IRONFISH_WALLET}
    if (( $nGR <= 1 )); then
        echo -e "${err}IRONFISH_GRAFFITI is empty. Please do 'export IRONFISH_GRAFFITI=<your_graffiti>'\n
Переменная Граффити пустая. Введите 'export IRONFISH_GRAFFITI=<ваш_граффити>'${end}"
        exit 1
    elif (( $nWL <= 1 )); then
        echo -e "${err}IRONFISH_WALLET is empty. Please do 'export IRONFISH_WALLET=<your_wallet>'\n
Переменная Кошелька пустая. Введите 'export IRONFISH_WALLET=<ваш_кошелек>'${end}"
        exit 1
    else
        echo -e "All good! / Все ок!"
    fi

echo -e "${fmt}\nSetting up dependencies / Устанавливаем необходимые зависимости${end}" && sleep 1
	cd $HOME
	sudo apt update
	sudo curl https://sh.rustup.rs -sSf | sh -s -- -y
    . $HOME/.cargo/env
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
	sudo apt install curl make clang pkg-config libssl-dev build-essential git jq nodejs -y < "/dev/null"

echo -e "${fmt}\nSaving config paramaters / Сохраняем переменные пользователя${end}" && sleep 1
    # export dependencies
    echo "export IRONFISH_GRAFFITI=$IRONFISH_GRAFFITI" >> $HOME/.bash_profile
    echo "export IRONFISH_WALLET=$IRONFISH_WALLET" >> $HOME/.bash_profile
    
    # verify deps
    echo "Your Graffiti is(ваш граффити): $IRONFISH_GRAFFITI"
    echo "Your Wallet Name is(имя кошелька): $IRONFISH_WALLET"

    # save graffiti in config
    mkdir -p $HOME/.ironfish
	echo "{
    \"nodeName\": \"${IRONFISH_GRAFFITI}\",
    \"blockGraffiti\": \"${IRONFISH_GRAFFITI}\"
}" > $HOME/.ironfish/config.json

echo -e "${fmt}\nInstalling IronFish cli / Устанавливаем интерфейс IronFish${end}" && sleep 1
    # install ironfish with npm
    sudo npm install -g ironfish

echo -e "${fmt}\nConfiguring service / Устанавливаем сервис${end}" && sleep 1
    # create service
    echo "[Unit]
Description=IronFish Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which ironfish) start
Restart=always
RestartSec=5
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
" > $HOME/ironfishd.service

    # mv service to service dir
    sudo mv $HOME/ironfishd.service /etc/systemd/system

echo -e "${fmt}\nStarting service / Запускаем сервис${end}" && sleep 1
    #
    sudo systemctl daemon-reload
    sudo systemctl enable ironfishd
    sudo systemctl restart ironfishd

echo -e "${fmt}\nChecking node status / Проверяем статус ноды" && sleep 5
    if [[ `service ironfishd status | grep active` =~ "running" ]]; then
        echo -e "${scss}\nYour node was installed succesfully\n
Нода была установлена правильно и сейчас активна.${end}"
    else
        echo -e "${err}Your node was not installed succesfully :(. Try reinstalling or ask for help in the chat.\n
Нода была установлена неправильно. Попробуйте переустановить или обращайтесь за помощью в наш чат.${end}"
        exit 1
    fi

echo -e "${fmt}\nImport account '$IRONFISH_WALLET' / Импортирую аккаунт '$IRONFISH_WALLET'${end}" && sleep 1
    # create
    ironfish wallet:import $HOME/.ironfish/keys/phase3_$IRONFISH_WALLET.json

    # use
    ironfish wallet:use $IRONFISH_WALLET

    echo -e "${scss}\nSuccess / Все ок${end}\nYour default wallet is now '$IRONFISH_WALLET' / Ваш кошелек по умолчанию теперь '$IRONFISH_WALLET'${end}" && sleep 1

    # output
    echo -e "${fmt}\nYou can also save it from the below output \ Вы также можете просто сохранить вывод ниже${end}
#~ cat $HOME/.ironfish/keys/phase3_$IRONFISH_WALLET.json" && sleep 1
    cat $HOME/.ironfish/keys/phase3_$IRONFISH_WALLET.json

echo -e "${fmt}\nEnabling Telemetry / Включаем телеметрию${end}" && sleep 1
    # telemetry
    ironfish config:set enableTelemetry true

echo -e "${fmt}\nInstalling snapshot / Устанавливаем снапшот${end}"
    # snapshot
    systemctl stop ironfishd && sleep 3
    ironfish chain:download --confirm && sleep 2
    systemctl restart ironfishd

echo -e "${fmt}\nSetup was successful / Установка завершена\n${end}" && sleep 1
