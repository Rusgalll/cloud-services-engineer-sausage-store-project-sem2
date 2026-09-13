FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /usr/src/app
COPY pom.xml checkstyle.xml ./
COPY src ./src

ARG VERSION=0.0.1-SNAPSHOT
RUN VERSION="${VERSION}" mvn --batch-mode --no-transfer-progress package \
    && cp target/sausage-store-${VERSION}.jar /usr/src/app/sausage-store.jar

FROM eclipse-temurin:17-jre-jammy

WORKDIR /app
RUN groupadd --system jaruser \
    && useradd --system --gid jaruser --no-create-home --shell /usr/sbin/nologin jaruser \
    && mkdir -p /logs/reports \
    && chown -R jaruser:jaruser /app /logs

ENV REPORT_PATH=/logs/reports \
    LOG_PATH=/logs

COPY --from=builder --chown=jaruser:jaruser /usr/src/app/sausage-store.jar ./sausage-store.jar

USER jaruser
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/sausage-store.jar"]
