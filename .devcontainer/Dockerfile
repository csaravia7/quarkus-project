FROM mcr.microsoft.com/devcontainers/java:1-21-bookworm

# El repo apt de Yarn de la imagen base tiene la clave GPG vencida y rompe el apt-get update de las features
RUN rm -f /etc/apt/sources.list.d/yarn.list
