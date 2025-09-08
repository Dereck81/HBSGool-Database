CREATE DATABASE hbsgool;

\c hbsgool;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE DOMAIN dni AS CHAR(8)
CHECK (VALUE ~ '^\d{8}$');

CREATE TABLE rol (
	id_rol UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
	rol VARCHAR(100) UNIQUE NOT NULL

);


CREATE TABLE estado_reservacion (
	id_estado_reservacion UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
	estado_reservacion VARCHAR(100) UNIQUE NOT NULL

);


CREATE TABLE estado_cancha (
	id_estado_cancha UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
	estado_cancha VARCHAR(100) UNIQUE NOT NULL

);


CREATE TABLE cajero (
	id_cajero UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
	nombre VARCHAR(255) NOT NULL,
	apellido_paterno VARCHAR(255) NOT NULL,
	apellido_materno VARCHAR(255) NOT NULL,
	dni dni UNIQUE NOT NULL,
	telefono CHAR(9) UNIQUE NOT NULL,
	activo BOOLEAN NOT NULL DEFAULT TRUE,
	CONSTRAINT chk_cajero_telefono CHECK (telefono ~ '^\d{9}$')

);


CREATE TABLE estado_pago (
	id_estado_pago UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
	estado_pago VARCHAR(255) UNIQUE NOT NULL

);


CREATE TABLE tipo_pago (
	id_tipo_pago UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
	tipo_pago VARCHAR(255) UNIQUE NOT NULL

);


CREATE TABLE tipo_movimiento (
	id_tipo_movimiento UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
	tipo_movimiento VARCHAR(255) UNIQUE NOT NULL

);


CREATE TABLE usuario (
	id_usuario UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
	rol_id UUID NOT NULL,
	nombre VARCHAR(255) NOT NULL,
	apellido_paterno VARCHAR(255) NOT NULL,
	apellido_materno VARCHAR(255) NOT NULL,
	dni dni UNIQUE NOT NULL,
	telefono CHAR(9) UNIQUE NOT NULL,
	email VARCHAR(255) UNIQUE NOT NULL,
	activo BOOLEAN NOT NULL DEFAULT TRUE,
	FOREIGN KEY (rol_id) REFERENCES rol(id_rol),
	CONSTRAINT chk_usuario_email CHECK (email ~ '^[a-zA-Z0-9_]+([.][a-zA-Z0-9_]+)*@[a-zA-Z0-9_]+([.][a-zA-Z0-9_]+)*[.][a-zA-Z]{2,5}$'),
	CONSTRAINT chk_usuario_telefono CHECK (telefono ~ '^\d{9}$')

);


CREATE TABLE cancha (
	id_cancha UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
	nombre VARCHAR(255) UNIQUE NOT NULL,
	descripcion TEXT NULL,
	ancho NUMERIC(5, 2) NULL,
	largo NUMERIC(5, 2) NULL,
	es_sintetico BOOLEAN NOT NULL,
	precio_hora NUMERIC(10, 2) NOT NULL,
	estado_cancha_id UUID NOT NULL,
	FOREIGN KEY (estado_cancha_id) REFERENCES estado_cancha(id_estado_cancha),
	CONSTRAINT chk_cancha_ancho CHECK (ancho >= 0),
	CONSTRAINT chk_cancha_largo CHECK (largo >= 0),
	CONSTRAINT chk_cancha_precio_hora CHECK (precio_hora >= 0) 

);


CREATE TABLE sesion_cajero (
	id_sesion_cajero UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
	cajero_id UUID NOT NULL,
	fecha_apertura TIMESTAMP NOT NULL,
	fecha_cierre TIMESTAMP,
	FOREIGN KEY (cajero_id) REFERENCES cajero(id_cajero)

);


CREATE TABLE review (
	id_review UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
	usuario_id UUID NOT NULL,
	rating SMALLINT NOT NULL,
	comentario TEXT NOT NULL,
	creado TIMESTAMP NOT NULL,
	FOREIGN KEY (usuario_id) REFERENCES usuario(id_usuario),
	CONSTRAINT chk_review_rating CHECK (rating >= 0 AND rating <= 5)

);


CREATE TABLE cierre_dia (
	id_cierre_dia UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
	usuario_id UUID NOT NULL,
	fecha DATE UNIQUE NOT NULL DEFAULT CURRENT_DATE,
	monto_teorico NUMERIC(6, 2) NOT NULL,
	monto_real NUMERIC(6, 2) NOT NULL,
	diferencia NUMERIC(6, 2) NOT NULL,
	FOREIGN KEY (usuario_id) REFERENCES usuario(id_usuario),
	CONSTRAINT chk_cierre_dia_monto_teorico CHECK (monto_teorico >= 0),
	CONSTRAINT chk_cierre_dia_monto_real CHECK (monto_real >= 0)

);


CREATE TABLE reservacion (
	id_reservacion UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
	usuario_id UUID UNIQUE NOT NULL,
	cancha_id UUID NOT NULL,
	estado_reservacion_id UUID NOT NULL,
	cajero_id UUID NOT NULL,
	tiempo_inicio TIMESTAMP UNIQUE NOT NULL,
	duracion INTERVAL NOT NULL,
	dnis dni[] NOT NULL,
	precio_total NUMERIC(10, 2) NOT NULL,
	FOREIGN KEY (usuario_id) REFERENCES usuario(id_usuario),
	FOREIGN KEY (cancha_id) REFERENCES cancha(id_cancha),
	FOREIGN KEY (estado_reservacion_id) REFERENCES estado_reservacion(id_estado_reservacion),
	FOREIGN KEY (cajero_id) REFERENCES cajero(id_cajero),
	CONSTRAINT chk_reservacion_precio_total CHECK (precio_total >= 0) 

);


CREATE TABLE reporte_cierre (
	id_reporte_cierre UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
	sesion_cajero_id UUID UNIQUE NOT NULL,
	fecha TIMESTAMP NOT NULL,
	monto_teorico NUMERIC(6, 2) NOT NULL,
	monto_real NUMERIC(6, 2) NOT NULL,
	diferencia NUMERIC(6, 2) NOT NULL,
	FOREIGN KEY (sesion_cajero_id) REFERENCES sesion_cajero(id_sesion_cajero),
	CONSTRAINT chk_reporte_cierre_monto_teorico CHECK (monto_teorico >= 0),
	CONSTRAINT chk_reporte_cierre_monto_real CHECK (monto_real >= 0)

);


CREATE TABLE penalidad (
	id_penalidad UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
	usuario_id UUID NOT NULL,
	reservacion_id UUID NOT NULL,
	razon TEXT NOT NULL,
	fecha_aplicada TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY (usuario_id) REFERENCES usuario(id_usuario),
	FOREIGN KEY (reservacion_id) REFERENCES reservacion(id_reservacion)

);


CREATE TABLE pago (
	id_pago UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
	reservacion_id UUID NOT NULL,
	estado_pago_id UUID NOT NULL,
	tipo_pago_id UUID NOT NULL,
	sesion_cajero_id UUID NOT NULL,
	fecha TIMESTAMP NOT NULL,
	FOREIGN KEY (reservacion_id) REFERENCES reservacion(id_reservacion),
	FOREIGN KEY (tipo_pago_id) REFERENCES tipo_pago(id_tipo_pago),
	FOREIGN KEY (sesion_cajero_id) REFERENCES sesion_cajero(id_sesion_cajero)

);


CREATE TABLE movimiento_boveda (
	id_movimiento_boveda UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
	reporte_cierre_id UUID NOT NULL,
	tipo_movimiento_id UUID NOT NULL,
	FOREIGN KEY (reporte_cierre_id) REFERENCES reporte_cierre(id_reporte_cierre),
	FOREIGN KEY (tipo_movimiento_id) REFERENCES tipo_movimiento(id_tipo_movimiento)

);


CREATE TABLE confirmacion_pago_remoto (
	id_confirmacion_pago_remoto UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
	pago_id UUID NOT NULL,
	usuario_id UUID NOT NULL,
	fecha TIMESTAMP NOT NULL,
	evidencia VARCHAR NOT NULL,
	FOREIGN KEY (pago_id) REFERENCES pago(id_pago),
	FOREIGN KEY (usuario_id) REFERENCES usuario(id_usuario)

);


