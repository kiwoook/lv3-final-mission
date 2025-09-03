#!/bin/bash

set -e

echo "🚀 Starting PROD deployment script..."

# 현재 실행 중인 prod 애플리케이션 중지
echo "🔄 Stopping existing prod application..."
PID=$(pgrep -f "lv2-final-mission-0.0.1-SNAPSHOT-prod.jar" || echo "")
if [ ! -z "$PID" ]; then
    echo "Found existing prod application with PID: $PID"
    kill -15 $PID
    sleep 15
    if kill -0 $PID 2>/dev/null; then
        echo "⚠️ Forcefully killing prod application"
        kill -9 $PID
    fi
    echo "✅ Production application stopped"
else
    echo "ℹ️ No existing production application found"
fi

# /opt 디렉토리 생성
echo "📁 Setting up /opt directory..."
sudo mkdir -p /opt/lv3-final-mission/prod
sudo chown -R $USER:$USER /opt/lv3-final-mission

# MySQL 데이터베이스 시작
echo "🗄️ Starting MySQL database..."
docker compose down || true
docker compose up -d
echo "✅ MySQL container started"

# MySQL 준비 대기
echo "⏳ Waiting for MySQL to be ready..."
timeout=60
while [ $timeout -gt 0 ] && ! docker exec lv3-final-mission-mysql mysqladmin ping -h"localhost" --silent; do
    echo "⏳ MySQL is not ready yet, waiting... ($timeout seconds left)"
    sleep 5
    timeout=$((timeout-5))
done
if [ $timeout -le 0 ]; then
    echo "❌ MySQL failed to start within 60 seconds"
    docker logs lv3-final-mission-mysql
    exit 1
fi
echo "✅ MySQL is ready!"

# JAR 파일 확인
JAR_FILE="lv2-final-mission-0.0.1-SNAPSHOT-prod.jar"
if [ ! -f "build/libs/$JAR_FILE" ]; then
    echo "❌ Expected JAR file not found: build/libs/$JAR_FILE"
    ls -la build/libs/
    exit 1
fi

# jar 파일을 /opt로 복사
echo "📋 Copying JAR file to /opt..."
cp build/libs/$JAR_FILE /opt/lv3-final-mission/prod/

# /opt에서 애플리케이션 실행
cd /opt/lv3-final-mission/prod
echo "🚀 Starting production application: $JAR_FILE"
java -jar -Dspring.profiles.active=prod $JAR_FILE > prod-app.log 2>&1 & disown

echo "✅ Production application deployment completed successfully!"
echo "📍 Location: /opt/lv3-final-mission/prod/"
echo "📋 Log file: /opt/lv3-final-mission/prod/prod-app.log"
echo "🌐 URL: http://localhost:8080"