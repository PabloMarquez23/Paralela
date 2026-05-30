# 🎯 Cambiamos el JDK de 17 a 21 para que coincida con tu compilación local
FROM eclipse-temurin:21-jre-jammy

WORKDIR /app

# Copiamos directamente el archivo JAR que acabas de compilar con IntelliJ/Nativo
COPY ./build/libs/*.jar app.jar

EXPOSE 8080

# Comando atómico de ejecución reactiva para WebFlux
ENTRYPOINT ["java", "-jar", "app.jar"]