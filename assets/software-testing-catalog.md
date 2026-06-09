---

name: software-test-catalog-format-senses-v3
description: "Skill para generar catálogos de casos de prueba funcionales en formato Markdown tabular. Adaptado para flujos con control de acceso por rol (Admisión/Psicólogo) y selección de tipo de búsqueda por dropdown."
trigger: /software-test-catalog-format
Versión: 3.0
Última actualización: 2026-06-08

---

## 1. OBJETIVO

Definir y estandarizar la generación de catálogos de casos de prueba funcionales en formato Markdown utilizando el estándar de QA del proyecto SENSES. La salida generada mapea los resultados de las técnicas de caja negra (PE, BVA, TD) a casos de prueba ejecutables, garantizando la inclusión de precondiciones de autenticación y controles dinámicos de interfaz (dropdown).

---

## 2. ESTRUCTURA OFICIAL DEL CATÁLOGO

La salida debe representarse obligatoriamente en una tabla Markdown con las siguientes 7 columnas:

| ID CP | Título | Técnicas | Pasos | Entrada | Resultado Esperado | Resultado Actual |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| CPF-BUS-001 | Búsqueda DNI - Entrada Válida | TCN-PE-BUS-ADM-001<br>TCN-TD-BUS-ADM-001 | 1. Loguear como Admisión.<br>2. Seleccionar "DNI" en la lista desplegable.<br>3. Ingresar DNI "00000003".<br>4. Buscar. | Rol: Admisión<br>Dropdown: "DNI"<br>DNI: "00000003" | Muestra paciente con el DNI exacto. | Correcto |

---

## 3. REGLAS DE GENERACIÓN (PROMPT ENG)

Al activar esta skill, el modelo debe ceñirse a las siguientes directrices:

* **Formato Tabular Estricto:** Devolver SIEMPRE la información estructurada en bloques de tabla de Markdown. No se debe agregar texto explicativo o introductorio fuera de la tabla.
* **Inclusión de Roles en Pasos:** Cada caso de prueba debe iniciar explícitamente con la precondición de autenticación, alternando entre los roles autorizados: **Loguear como Admisión** o **Loguear como Psicólogo**.
* **IDs Correlativos:** Generar códigos identificadores de forma secuencial y automática (`CPF-BUS-001`, `CPF-BUS-002`, etc.).
* **Trazabilidad de Técnicas:** Reutilizar y mapear explícitamente los códigos de las técnicas de diseño previas (PE, BVA, TD).
* **Resultados Verificables:** Redactar pasos secuenciales claros y resultados esperados cortos, objetivos y funcionales.

---

## 4. ESPECIFICACIÓN DE COLUMNAS

### A. ID CP (Identificador del Caso de Prueba)
* **Formato:** `CPF-[MODULO]-00X`
* *Ejemplos:* `CPF-BUS-001`, `CPF-BUS-002`

### B. Título
* **Formato:** `[Funcionalidad] - [Escenario]`
* *Ejemplos:* `Búsqueda DNI - Campo Vacío`, `Búsqueda Nombre - Filtro Único por Nombre`

### C. Técnicas
* Lista de códigos de técnicas asociadas, separados por comas.
* *Ejemplo:* `TCN-PE-BUS-ADM-001<br>TCN-BVA-BUS-ADM-001`

### D. Pasos
* Lista secuencial y ordenada de las acciones. Debe incluir el login, la interacción con la lista desplegable de tipo de búsqueda, la inserción de datos y la ejecución. Se usa `<br>` para saltos de línea dentro de la celda.
* *Ejemplo:* `1. Loguear como Psicólogo.<br>2. Seleccionar "DNI" en la lista desplegable.<br>3. Ingresar DNI "3".<br>4. Buscar.`

### E. Entrada
* Los valores exactos organizados por componente (Rol, Dropdown y campos de texto abiertos) envueltos entre comillas.
* *Ejemplo:* `Rol: Psicólogo<br>Dropdown: "DNI"<br>DNI: "3"`

### F. Resultado Esperado
* Descripción clara y funcional del comportamiento del sistema.
* *Ejemplos:* `Muestra paciente con el DNI exacto`, `El campo bloquea o rechaza la entrada de caracteres alfanuméricos.`

### G. Resultado Actual
* Estado de la ejecución. Valores permitidos: `Correcto`, `Incorrecto`, `Falla`, `Rechaza`, `Por validar`.

---

## 5. EJEMPLO COMPLETO DE REFERENCIA

```md
| ID CP | Título | Técnicas | Pasos | Entrada | Resultado Esperado | Resultado Actual |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| CPF-BUS-001 | Búsqueda DNI - Entrada Válida (Exacta) | TCN-PE-BUS-ADM-001, TCN-TD-BUS-ADM-001 | 1. Loguear como Admisión.<br>2. Seleccionar "DNI" en la lista desplegable.<br>3. Ingresar DNI "00000003".<br>4. Buscar. | Rol: Admisión<br>Dropdown: "DNI"<br>DNI: "00000003" | Muestra paciente con el DNI exacto. | Correcto |
| CPF-BUS-019 | Desplegable - Cambio de Vista a "Nombre y Apellido" | TCN-PE-BUS-ADM-002 | 1. Loguear como Admisión.<br>2. Cambiar la selección de la lista desplegable de "DNI" a "Nombre y Apellido".<br>3. Observar la interfaz. | Rol: Admisión<br>Dropdown: Cambia a "Nombre y Apellido" | Se oculta el campo de texto de DNI; se muestran y habilitan los campos "First Name" y "Last Name". | Correcto |