# README

## 既存のrailsアプリをdockerにて起動させる方法

### 1. 既存のrailsアプリのレポジトリから[git clone]する
```
$ git clone https://github.com/shiba30/rails-docker.git
$ cd rails-docker
```

### 2. Dockerfileを作成する
```
$ vim Dockerfile

FROM ruby:3.0.2

COPY --from=node /opt/yarn-* /opt/yarn
COPY --from=node /usr/local/bin/node /usr/local/bin/
COPY --from=node /usr/local/lib/node_modules/ /usr/local/lib/node_modules/
RUN ln -fs /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
  && ln -fs /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npx \
  && ln -fs /opt/yarn/bin/yarn /usr/local/bin/yarn \
  && ln -fs /opt/yarn/bin/yarnpkg /usr/local/bin/yarnpkg
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev

RUN mkdir /repogitory_name
WORKDIR /repogitory_name
ADD Gemfile /repogitory_name/Gemfile
ADD Gemfile.lock /repogitory_name/Gemfile.lock
RUN bundle install
ADD package.json yarn.lock /repogitory_name/
RUN yarn install
ADD . /repogitory_name

```

### 3. docker-composeを作成する
```
$ vim docker-compose.yml

version: '3'
services:
  db:
    image: postgres:14.6-alpine
    environment:
      - POSTGRES_PASSWORD=password
  web:
    image: repogitory_name:latest
    build: .
    command: bundle exec rails s -p 3000 -b '0.0.0.0'
    volumes:
      - .:/repogitory_name
    ports:
      - "3000:3000"
    environment:
      - POSTGRES_PASSWORD=password
    depends_on:
      - db
```

### 4. database.ymlにpostgresの設定がされているか確認する
```
$ vim config/database.yml

default: &default
  adapter: postgresql
  encoding: unicode
  host: db
  username: postgres
  password: <%= ENV['POSTGRES_PASSWORD'] %>
  pool: 5

development:
  <<: *default
  database: myproject_development

test:
  <<: *default
  database: myproject_test
```

### 5. Gemfileの設定を確認する
- Dockerfileに記載しているrubyバージョンを合わせる
- postgresの設定
```
$ vim Gemfile

ruby '3.0.2'

# Use postgres as the database for Active Record
gem 'pg'

```

### 6. docker ビルドする
```
$ docker-compose build
[+] Building 5.2s (22/22) FINISHED                                                                          
 => [internal] load build definition from Dockerfile                                                   0.0s
 => => transferring dockerfile: 32B                                                                    0.0s
 => [internal] load .dockerignore                                                                      0.0s
 => => transferring context: 2B                                                                        0.0s
 => [internal] load metadata for docker.io/library/ruby:3.0.2                                          1.8s
 => [auth] library/ruby:pull token for registry-1.docker.io                                            0.0s
 => [stage-1  1/14] FROM docker.io/library/ruby:3.0.2@sha256:15dd21ae353c5f4faebed038d9d131c47b9fd84c  0.0s
 => [internal] load build context                                                                      0.6s
 => => transferring context: 9.56MB                                                                    0.6s
 => FROM docker.io/library/node:latest                                                                 0.9s
 => => resolve docker.io/library/node:latest                                                           0.9s
 => [auth] library/node:pull token for registry-1.docker.io                                            0.0s
 => CACHED [stage-1  2/14] COPY --from=node /opt/yarn-* /opt/yarn                                      0.0s
 => CACHED [stage-1  3/14] COPY --from=node /usr/local/bin/node /usr/local/bin/                        0.0s
 => CACHED [stage-1  4/14] COPY --from=node /usr/local/lib/node_modules/ /usr/local/lib/node_modules/  0.0s
 => CACHED [stage-1  5/14] RUN ln -fs /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/n  0.0s
 => CACHED [stage-1  6/14] RUN apt-get update -qq && apt-get install -y build-essential libpq-dev      0.0s
 => CACHED [stage-1  7/14] RUN mkdir /repogitory_name                                                  0.0s
 => CACHED [stage-1  8/14] WORKDIR /repogitory_name                                                    0.0s
 => CACHED [stage-1  9/14] ADD Gemfile /repogitory_name/Gemfile                                        0.0s
 => CACHED [stage-1 10/14] ADD Gemfile.lock /repogitory_name/Gemfile.lock                              0.0s
 => CACHED [stage-1 11/14] RUN bundle install                                                          0.0s
 => CACHED [stage-1 12/14] ADD package.json yarn.lock /repogitory_name/                                0.0s
 => CACHED [stage-1 13/14] RUN yarn install                                                            0.0s
 => [stage-1 14/14] ADD . /repogitory_name                                                             1.5s
 => exporting to image                                                                                 0.9s
 => => exporting layers                                                                                0.9s
 => => writing image sha256:a0583596630499cefff0c97d8fc2c1d9897e11de3f873398a5649826fc1a4285           0.0s
 => => naming to docker.io/library/repogitory_name:latest 
```


### 7. DB作成&migrateを行う
```
$ docker-compose run web rails db:create db:migrate
[+] Running 9/9
 ⠿ db Pulled                                                                                          43.9s
   ⠿ a9eaa45ef418 Pull complete                                                                        2.5s
   ⠿ 6004074ad02a Pull complete                                                                        2.6s
   ⠿ 690395976a32 Pull complete                                                                        2.6s
   ⠿ 73fa4f129f16 Pull complete                                                                       39.0s
   ⠿ 0a7be7d8ad8b Pull complete                                                                       39.0s
   ⠿ 96306ea206e7 Pull complete                                                                       39.0s
   ⠿ b5037d9b606d Pull complete                                                                       39.1s
   ⠿ 642fbc6f316e Pull complete                                                                       39.1s
[+] Running 2/2
 ⠿ Network rails-docker_default  Created                                                               0.0s
 ⠿ Container rails-docker-db-1   Created                                                               0.1s
[+] Running 1/1
 ⠿ Container rails-docker-db-1  Started                                                                0.2s
Created database 'myproject_development'
Created database 'myproject_test'
== 20230221092316 CreateTasks: migrating ======================================
-- create_table(:tasks)
   -> 0.0051s
== 20230221092316 CreateTasks: migrated (0.0051s) =============================
```


### 8. docker-compose up で起動する
```
MacBook-Air:rails-docker taipon512$ docker-compose up
[+] Running 2/2
 ⠿ Container rails-docker-db-1   Recreated                                                             0.1s
 ⠿ Container rails-docker-web-1  Created                                                               0.0s
Attaching to rails-docker-db-1, rails-docker-web-1
rails-docker-db-1   | 
rails-docker-db-1   | PostgreSQL Database directory appears to contain a database; Skipping initialization
rails-docker-db-1   | 
rails-docker-db-1   | 2023-04-15 00:10:35.958 UTC [1] LOG:  starting PostgreSQL 14.6 on aarch64-unknown-linux-musl, compiled by gcc (Alpine 12.2.1_git20220924-r4) 12.2.1 20220924, 64-bit
rails-docker-db-1   | 2023-04-15 00:10:35.958 UTC [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
rails-docker-db-1   | 2023-04-15 00:10:35.958 UTC [1] LOG:  listening on IPv6 address "::", port 5432
rails-docker-db-1   | 2023-04-15 00:10:35.960 UTC [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
rails-docker-db-1   | 2023-04-15 00:10:35.964 UTC [22] LOG:  database system was shut down at 2023-04-15 00:10:35 UTC
rails-docker-db-1   | 2023-04-15 00:10:35.966 UTC [1] LOG:  database system is ready to accept connections
rails-docker-web-1  | => Booting Puma
rails-docker-web-1  | => Rails 6.0.6.1 application starting in development 
rails-docker-web-1  | => Run `rails server --help` for more startup options
rails-docker-web-1  | Puma starting in single mode...
rails-docker-web-1  | * Version 4.3.12 (ruby 3.0.2-p107), codename: Mysterious Traveller
rails-docker-web-1  | * Min threads: 5, max threads: 5
rails-docker-web-1  | * Environment: development
rails-docker-web-1  | * Listening on tcp://0.0.0.0:3000
rails-docker-web-1  | Use Ctrl-C to stop
```



### 9. ブラウザで、 http://127.0.0.1:3000/ にアクセスする
```
rails-docker-web-1  | Started GET "/" for 192.168.160.1 at 2023-04-15 00:11:37 +0000
rails-docker-web-1  | Cannot render console from 192.168.160.1! Allowed networks: 127.0.0.0/127.255.255.255, ::1
rails-docker-web-1  |    (0.6ms)  SELECT "schema_migrations"."version" FROM "schema_migrations" ORDER BY "schema_migrations"."version" ASC
rails-docker-web-1  | Processing by TasksController#index as HTML
rails-docker-web-1  |   Rendering tasks/index.html.erb within layouts/application
rails-docker-web-1  |   Task Load (0.4ms)  SELECT "tasks".* FROM "tasks"
rails-docker-web-1  |   ↳ app/views/tasks/index.html.erb:16
rails-docker-web-1  |   Rendered tasks/index.html.erb within layouts/application (Duration: 4.9ms | Allocations: 2086)
rails-docker-web-1  | [Webpacker] Everything's up-to-date. Nothing to do
rails-docker-web-1  | Completed 200 OK in 76ms (Views: 61.8ms | ActiveRecord: 1.2ms | Allocations: 13266)
rails-docker-web-1  | 
rails-docker-web-1  | 
```
