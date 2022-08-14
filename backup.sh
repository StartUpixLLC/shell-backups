# [LKoshev]
BackupPath="/Users/leonidkoshcheev/backups/project_1/" # Куда архивировать (создайтие эту директорию вручную)

# Делаем бэкап базы данных при необходимости
DbUser="root"
DbPass="" # Обязательно экранируйте спецсимволы
DbPort=""
DbName="db_name" # Оставьте пустым, чтобы пропустить бэкап БД

BackupName="project.tgz" # Имя архива
TargetPath="/var/www/html/project_1/" # Что архивировать
BackupsCount=5 # Сколько бэкапов храним

if [ $DbName ]; then
  echo "Делаем бэкап базы данных" "$DbName"
  # Бэкап БД будет сделан в директорию, в которой находится сам .sh скрипт
  mysqldump -u"$DbUser" -p"$DbPass" --port="$DbPort" "$DbName" > "$TargetPath"/"$DbName".sql
  # docker exec [CONTAINER] /usr/bin/mysqldump -u"$DbUser" --password="$DbPass" [DB_NAME] > "$TargetPath"/"$DbName".sql
fi

# Определяем номер следующего бэкапа
j=1
while [ "$j" -le "$BackupsCount" ]; do
  if [ -e "$BackupPath""$j"_"$BackupName" ]; then
    j=$(( j + 1 ))
  else
    break
  fi
done

# Если нет директории, создаем ее
if [ ! -e "$BackupPath" ]; then
  echo "Нет директории" "$BackupPath" ", создаем."
  mkdir -p $BackupPath
fi

# Если номер следующего бэкапа меньше максимального, просто бэкапим
if [ "$j" -le "$BackupsCount" ]; then
  $( tar -czvf "$BackupPath""$j"_"$BackupName" "$TargetPath" )

# В противном случае номер следующего бэкапа - это максимальный бэкап
else
  j=$BackupsCount

  # Перебираем все бэкапы, чтобы сместить их на один вверх
  i=1
  while [ "$i" -le "$BackupsCount" ]; do
    if [ $i -eq 1 ]; then
      rm -rf "$BackupPath""$i"_"$BackupName"
    else
      cp "$BackupPath""$i"_"$BackupName" "$BackupPath"$(($i-1))"_""$BackupName"
    fi
    i=$(( i + 1 ))
  done

  # Удаляем крайний и делаем свежий вместо него
  rm -rf "$BackupPath""$j"_"$BackupName"
  $( tar -czvf "$BackupPath""$j"_"$BackupName" "$TargetPath" )
fi

if [ $DbName ]; then
  rm -rf "$TargetPath"/"$DbName".sql
fi

Final="$BackupPath""$j"_"$BackupName"
Size=$(wc -c $Final | awk '{print $1}')

# При необходимости отправляем уведомление о завершении в telegram
#curl "https://api.telegram.org/bot[BOT:TOKEN]//sendMessage?chat_id=-[Chat ID]&parse_mode=html&text=<b>\[Leonidkoshcheev\]</b> Backup $Final is done. File size: <b>"$Size"b</b>" >/dev/null 2>&1
