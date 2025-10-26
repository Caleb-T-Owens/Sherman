FROM node:lts-bookworm

COPY . /app

WORKDIR /app

RUN npm install
RUN npm run build
CMD npm run serve:ssr:website3
