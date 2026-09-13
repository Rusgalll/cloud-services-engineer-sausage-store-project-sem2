# Для Angular 6 и зафиксированной версии node-sass 4.9.x используется Node 10
# В итоговый образ копируются только собранные статические файлы
FROM node:10.24.1-buster AS builder

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --no-audit
COPY . .
RUN npm run build

FROM nginx:stable-alpine

ENV BACKEND_URL=http://backend:8080
COPY nginx.conf.template /etc/nginx/templates/default.conf.template
COPY --from=builder /app/dist/frontend/ /usr/share/nginx/html/

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
