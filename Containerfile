FROM docker.io/node:19.3-slim
WORKDIR .
COPY . .
RUN npm install
EXPOSE  3000
CMD ["node", "main.js"]
