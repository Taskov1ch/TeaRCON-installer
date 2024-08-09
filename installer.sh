#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Переменная для хранения пути к используемому Python
PYTHON_EXEC=""

# Функция для отображения анимации загрузки
show_loading_animation() {
	local pid=$1
	local delay=0.1
	local spinstr='|/-\'  # Символы для анимации
	while kill -0 $pid 2>/dev/null; do
		local temp=${spinstr#?}
		printf " [%c]  " "$spinstr"
		spinstr=$temp${spinstr%"$temp"}
		sleep $delay
		printf "\r"  # Возврат в начало строки
	done
	printf "\r"  # Стираем анимацию перед выводом следующего текста
}

# Функция для обработки ошибок
error_exit() {
	echo -e "${RED}Произошла ошибка. Скрипт завершен.${NC}"
	exit 1
}

# Установка обработчика ошибок
trap 'error_exit' ERR

# Удаление всех файлов и папок, кроме самого скрипта
echo -e "${YELLOW}Удаление всех файлов и папок, кроме самого скрипта разумеется :) ...${NC}"
find . -mindepth 1 ! -name "$(basename "$0")" -exec rm -rf {} + &
show_loading_animation $!

# Проверка доступной версии Python
find_available_python() {
	for python_version in $(ls /usr/bin/python3.* 2>/dev/null); do
		version=$(echo $python_version | grep -oP '(?<=python3\.)\d+')
		if [ "$version" -ge 10 ]; then
			PYTHON_EXEC=$python_version
			echo -e "${GREEN}Найдена подходящая версия: $($PYTHON_EXEC --version)${NC}"
			return 0
		fi
	done
	return 1
}

# Функция для установки Python и его компонентов
install_python() {
	echo -e "${YELLOW}Установка Python и его компонентов...${NC}"
	(
		apt update > /dev/null 2>&1 &&
		apt install -y software-properties-common > /dev/null 2>&1 &&
		add-apt-repository ppa:deadsnakes/ppa -y > /dev/null 2>&1 &&
		apt update > /dev/null 2>&1 &&
		apt install -y python3.10 python3.10-venv python3.10-dev python3.10-distutils python3-pip > /dev/null 2>&1
	) &
	show_loading_animation $!
	
	# Настройка альтернативных команд для Python и pip
	update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1 > /dev/null 2>&1
	
	PYTHON_EXEC="/usr/bin/python3.10"
}

# Проверка и выбор Python версии 3.10 или выше
if ! find_available_python; then
	install_python
fi

# Установка wget
if command -v wget &> /dev/null; then
	echo -e "${GREEN}wget уже установлен.${NC}"
else
	echo -e "${YELLOW}Установка wget...${NC}"
	apt install -y wget > /dev/null 2>&1 &
	show_loading_animation $!
fi

# Загрузка последнего релиза TeaRCON
echo -e "${YELLOW}Загрузка последнего релиза TeaRCON...${NC}"
latest_release_url=$(curl -s https://api.github.com/repos/teanus/Telegram-RCON-Bot/releases/latest | grep "tarball_url" | cut -d '"' -f 4)
echo -e "${GREEN}URL последнего релиза: $latest_release_url${NC}"
wget -O bot.tgz "$latest_release_url" > /dev/null 2>&1 &
show_loading_animation $!

# Проверка успешности загрузки
if [ ! -f bot.tgz ]; then
	echo -e "${RED}Ошибка загрузки файла bot.tgz${NC}"
	exit 1
fi

# Распаковка архива
tar -xzf bot.tgz

# Определение имени распакованной папки
extracted_folder=$(tar -tzf bot.tgz | head -1 | cut -f1 -d"/")
if [ -z "$extracted_folder" ]; then
	echo -e "${RED}Не удалось определить имя распакованной папки${NC}"
	exit 1
fi

# Перемещение содержимого в текущую директорию и удаление старой папки
mv -f "$extracted_folder"/* .
rm -rf "$extracted_folder"

# Удаление старого виртуального окружения (если оно существует)
if [ -d "venv" ]; then
	rm -rf venv
fi

# Создание нового виртуального окружения
echo -e "${YELLOW}Создание виртуального окружения venv...${NC}"
apt install -y python3.10-venv > /dev/null 2>&1 &
show_loading_animation $!
$PYTHON_EXEC -m venv venv > /dev/null 2>&1 &
show_loading_animation $!

# Активируем виртуальное окружение
source venv/bin/activate

# Установка зависимостей из requirements.txt
echo -e "${YELLOW}Установка зависимостей...${NC}"
if [ -f "requirements.txt" ]; then
	pip install -r requirements.txt > /dev/null 2>&1 &
	show_loading_animation $!
else
	echo -e "${RED}Файл requirements.txt не найден.${NC}"
	exit 1
fi

# Удаление ненужного архива
rm bot.tgz

# Создание файла start.sh с командами для активации окружения и запуска бота
echo -e "${YELLOW}Создание start.sh...${NC}"
echo "#!/bin/bash" > start.sh
echo "source venv/bin/activate" >> start.sh
echo "python bot.py" >> start.sh

# Сделать файл start.sh исполняемым
chmod +x start.sh

# Готово!
echo -e "${GREEN}Установка завершена!\nВы можете запустить бота командой \`./start.sh\`, но перед этим не забудьте его настроить.\nСкрипт создан Taskovich'ем (https://taskovich.pro).\nУдачного использования бота ;)${NC}"