#!/bin/bash

set -e

echo "🚀 Starting DEV deployment script..."

# 현재 실행 중인 dev 애플리케이션 중지
echo "🔄 Stopping existing dev application..."
PID=$(pgrep -f "lv2-final-mission-0.0.1-SNAPSHOT-dev.jar" || echo "")
if [ ! -z "$PID" ]; then
    echo "Found existing dev application with PID: $PID"
    kill -15 $PID
    sleep 10
    if kill -0 $PID 2>/dev/null; then
        echo "⚠️ Forcefully killing dev application"
        kill -9 $PID
    fi
    echo "✅ Dev application stopped"
else
    echo "ℹ️ No existing dev application found"
fi

# /opt 디렉토리 생성
echo "📁 Setting up /opt directory..."
sudo mkdir -p /opt/lv3-final-mission/dev
sudo chown -R $USER:$USER /opt/lv3-final-mission

# JAR 파일 확인
JAR_FILE="lv2-final-mission-0.0.1-SNAPSHOT-dev.jar"
if [ ! -f "build/libs/$JAR_FILE" ]; then
    echo "❌ Expected JAR file not found: build/libs/$JAR_FILE"
    ls -la build/libs/
    exit 1
fi

# jar 파일을 /opt로 복사
echo "📋 Copying JAR file to /opt..."
cp build/libs/$JAR_FILE /opt/lv3-final-mission/dev/

# /opt에서 애플리케이션 실행 (새로운 세션으로 완전 분리)
cd /opt/lv3-final-mission/dev
echo "🚀 Starting dev application: $JAR_FILE"
setsid nohup java -jar -Dspring.profiles.active=dev $JAR_FILE > dev-app.log 2>&1 < /dev/null &

echo "✅ Dev application deployment completed successfully!"
echo "📍 Location: /opt/lv3-final-mission/dev/"
echo "📋 Log file: /opt/lv3-final-mission/dev/dev-app.log"
echo "🌐 URL: http://localhost:8081"