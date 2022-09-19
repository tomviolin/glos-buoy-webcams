
all: build run

build:
	docker build -t glosbuoys .



run:	stop start

stop:
	docker kill glosbuoys || echo ""

start:
	docker rm glosbuoys || echo ""
	docker run -d --name glosbuoys --restart always glosbuoys

