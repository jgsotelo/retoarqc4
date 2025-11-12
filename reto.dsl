workspace "Reto" "Arquitectura de Integracion" {

    !identifiers hierarchical

    model {
    
        properties {
            "structurizr.groupSeparator" "/"
        }

        customer = person "Personal Banking Customer" "El usuario final del sistema de banca por internet"
        
        coreLegacySystem = softwareSystem "Core Banking System Legacy" "El sistema legacy de registro de cuentas de productos y transacciones." {
            tags "Internal"
        }
        
        coreNewSystem = softwareSystem "Core Banking System New" "El nuevo sistema de registro de clientes" {
            tags "Internal"
        }
        
        okta = softwareSystem "Okta" "El proveedor de identidad externo para gestionar la autenticación y autorización de usuarios a través de OAuth2.0/OIDC." {
            tags "External"
        }
        
        civilRegistry = softwareSystem "Civil Registry Ecuador" "Servicio de terceros para la verificación biométrica durante el proceso de incorporación del cliente." {
            tags "External"
        }
        
        openFinance = softwareSystem "Open Finance" "Proporciona API estandarizadas para acceder a datos con el consentimiento del cliente procedentes de otras instituciones financieras." {
            tags "External"
        }
        
        clickToPayService = softwareSystem "Click to Pay" "Proveedor Thales, C2P estándar de pago externo (basado en EMV SRC) que permite el pago sin tarjeta mediante un identificador digital." "API REST" {
            tags "External"
        }
        
        auditSystem = softwareSystem "Audit System" "Gestiona el registro, almacenamiento y recuperación de todas las acciones del consumidor." {
            tags "Internal", "Compliance"
            
            messageBroker = container "Message Broker" "Un bus de eventos para la comunicación asíncrona y desacoplada entre servicios." "Event Hubs" {
                tags "Broker"
            }
            
            auditService = container "Audit Service" "Gestiona la persistencia de los eventos del registro de auditoría de forma asíncrona." "Azure Function/Spring Boot" {
                tags "Function", "Pattern: Event Consumer"
            }
            
            auditDatabase = container "Audit Database" "Una base de datos relacional para almacenar todos los registros de auditoría de acciones del cliente." "Azure SQl Database/PostgreSQL" {
                tags "Database"
            }
            
            auditService -> messageBroker "Consume eventos de auditoría" "Event Driven/AMQP"
            auditService -> messageBroker "Notificación de reintento posterior para eventos de error (3)" "AMQP"
            auditService -> auditDatabase "Escribe registro de auditoría" "JDBC/TLS"
        }
        
        identitySystem = softwareSystem "Identity System" "Sistema de identidad de usuario que utiliza servicios externos para gestionar la autenticación." {
            tags "Internal"
            
            onboardingService = container "Onboarding Service" "Gestiona el registro de nuevos clientes y la verificación biométrica facial." "Spring boot" {
                tags "Microservice"
            }
            
            authenticationService = container "Authenticate Service" "El servicio OAuth2.0 existente de la compañía para gestionar la autenticación de usuarios." "Spring boot" {
                tags "Microservice"
            }
            
            cache = container "Cache" "Una caché en memoria para la identidad del cliente a la que se accede con frecuencia para reducir la latencia." "Patron Cache-Aside/Redis" {
                tags "Database"
            }
            
            onboardingService -> civilRegistry "Verificación de la información y validación biométrica" "API/MTLS-HTTPS"
            onboardingService -> okta "Crea una nueva identidad de usuario" "API/MTLS-HTTPS"
            onboardingService -> openFinance "Obtencion de datos y productos de cliente" "API/MTLS-HTTPS"
            authenticationService -> okta "Autenticación vía API" "API/MTLS-HTTPS"
            authenticationService -> cache "Reads/writes autenticación (Ref Time Session)" "TCP/IP"
        }
        
        notificationSystem = softwareSystem "Notification System" "Un servicio interno utilizado para enviar notificaciones transaccionales a los clientes (correo electrónico, SMS y notificaciones push)."{
            tags "Internal"
            
            notificationBroker = container "Message Broker" "Un bus de eventos para la comunicación asíncrona y desacoplada entre servicios." "Event Hubs" {
                tags "Broker"
            }
            
            notificationsService = container "Notification Service" "Un microservicio que abstrae los detalles del envío de notificaciones a través de diferentes canales." "Azure Function/Spring Boot" {
                tags "Function", "Pattern: Event Consumer"
            }
            
            notifyDatabase = container "Notify Database" "Una base de datos relacional para almacenar todos los registros de auditoría de acciones del cliente." "Azure SQL Database/PostgreSQL" {
                tags "Database"
            }
            
            acs = container "Azure Communication Services" "Plataforma como servicio (PaaS) para el envío de correos electrónicos y SMS transaccionales." "Azure Communication Services" {
                tags "External"
            }
            
            anh = container "Azure Notification Hubs" "Plataforma como servicio (PaaS) para gestionar y enviar notificaciones push multiplataforma." "Azure Notification Hubs" {
                tags "External"
            }
            
            azureStorageAccount = container "Azure Storage Account" "Cloud storage used to host static assets, specifically HTML templates for email notifications." "Azure Account Service" {
                tags "File"
            }
            
            notificationsService -> notificationBroker "Consume eventos de notificación" "AMQP"
            notificationsService -> notificationBroker "Notificación de reintento posterior para eventos de error (3)" "AMQP"
            notificationsService -> azureStorageAccount "Busca plantilla de notificacion en Storage" "API/SDK"
            notificationsService -> acs "Envía correos electrónicos y SMS transaccionales." "API/SDK"
            notificationsService -> anh "Envía notificaciones push mediante etiquetas" "API/SDK"
            notificationsService -> notifyDatabase "Escribe registros de notificaciones fallidas" "JDBC/TLS"
        }
        
        digitalbanking = softwareSystem "Digital Banking" "La plataforma diseñada ofrece pago de servicios de comercios externos." {
            tags "DigitalBanking"
            
            spa = container "Web Application" "Aplicación web de una sola página (SPA) orientada al cliente, desarrollada con React, que se ejecuta en el navegador." "React" {
                tags "Web"
            }
            
            mobile = container "Mobile Application" "La aplicación móvil multiplataforma para iOS y Android." "React Native" {
                tags "App"
            }
            
            cache = container "Cache" "Una caché en memoria para los datos de clientes a los que se accede con frecuencia para reducir la latencia." "Cache-Aside Pattern/Redis" {
                tags "Database"
            }
            
            apiGateway = container "Api Gateway" "Punto único de entrada para todas las solicitudes de clientes. Gestiona el enrutamiento, la seguridad y la limitación de invocaciones." "Gateway Pattern/Azure Api Management" {
                tags "Api"
            }
            
            group "AKS - Contingencia - East US 2" {
                group "AKS - Produccion - West US" {
                    group "Autoscaling for demand" {
                        digitalbankingService = container "Experience Bank Service" "Servicio encargado de coordinar las integraciones necesarias para facilitar la integración con la interfaz de usuario." "BFF Pattern/Spring boot" {
                            tags "Microservice"
                            
                            serviceController = component "Payment API Controller" "Recibe y valida las solicitudes de pago entrantes (POST /experience/payments/initiate) y delega la orquestación al componente central." "Spring Boot" {
                                tags "Component"
                            }
                            
                            paymentInitiationClient = component "Payment Initiation Client" "Cliente HTTP interno utilizado para invocar el endpoint /api/v1/payments/initiate del Payment Initiation Service." "Spring Webflux/WebClient" {
                                tags "Componente"
                            }
                            
                            identityClient = component "Identity System Client" "Componente responsable de interactuar con el IdP (Okta/Auth0) para el canje de código por token (PKCE), rotación de tokens (refresh) y gestión de sesiones de usuario." "Spring Webflux/WebClient" {
                                tags "Componente", "Seguridad"
                            }
                            
                            rsaEncryptionComponent = component "RSA Cryptography Service" "Gestiona el cifrado y descifrado simétrico de datos confidenciales mediante claves públicas/privadas RSA." "Spring Security/JCA (Java)" {
                                tags "Seguridad", "Compliance"
                            }
                            
                            serviceController -> identityClient "Verifica la validez y los 'scopes' del Access Token" "API"
                            serviceController -> paymentInitiationClient "Envía la solicitud de pago programado" "JSON/HTTPS"
                            serviceController -> rsaEncryptionComponent "Desencripta infromacion sensible con llaves public/private de red publica" 
                            serviceController -> rsaEncryptionComponent "Encripta informacion sensible con llaves public/private de red privada" 
                        }
                    
                        fraudDetectionService = container "Fraud Detection" "Un servicio especializado en tiempo real que evalúa la puntuación de riesgo de una transacción basándose en datos conductuales, históricos y contextuales." "Spring Boot" {
                            tags "Microservice"
                        }
                        
                        coreLegacyService = container "Conector Core Legacy Service" "Construyendo un conector centralizado que sirva de interfaz con el sistema core (legacy)." "Spring Boot" {
                            tags "Microservice", "Pattern: ACL", "Pattern: Strangler Fig"
                        }
                        
                        transactionAuthorizationService = container "Transaction Authorization" "Un sistema que evalúa las solicitudes de transacciones en tiempo real según motores de reglas (límites, riesgo, puntuaciones de fraude) para emitir aprobaciones o rechazos." "Spring Boot" {
                            tags "Microservice"
                        }
                        
                        paymentExecutionService = container "Payment Execution" "El sistema central responsable de registrar los débitos y créditos reales de fondos, interactuando directamente con las infraestructuras de pago externas." "Spring Boot" {
                            tags "Microservice"
                        }
                        
                        paymentInitiationService = container "Payment Initiation" "Gestiona la lógica empresarial y la orquestación de todas las validacion y pagos de servicio." "Spring Boot" {
                            tags "Microservice", "Pattern: Orchestrator"
                            
                            paymentController = component "Payment API Controller" "Recibe y valida las solicitudes de pago entrantes (POST /payments/initiate) y delega la orquestación al componente central." "Spring Boot" {
                                tags "Component"
                            }
                            
                            paymentOrchestrator = component "Payment Orchestrator" "Componente central que coordina secuencialmente la Validación, la Detección de Fraude, la Autorización de Transacción y la Ejecución de Pago." "Spring Boot" {
                                tags "Component"
                            }
                            
                            redisClient = component "Redis Cache Client" "Componente del cliente responsable de implementar la lógica Cache-Aside (lectura directa, escritura directa) con la caché del cliente." "Jedis/Spring Data Redis" {
                                tags "Component"
                            }
                            
                            coreClient = component "Core System Service Client" "Un cliente HTTP para la comunicación interna con el Servicio del Sistema Central." "Spring Webflux/WebClient" {
                                tags "Component"
                            }
                            
                            tasClient = component "Transaction Authorization Client" "Un cliente HTTP reactivo para la comunicación síncrona con el Sistema de Autorización de Transacciones (TAS) para solicitar la aprobación/rechazo en tiempo real." "Spring Webflux/WebClient" {
                                tags "Componente"
                            }
                            
                            pesClient = component "Payment Execution Client" "Un cliente HTTP para enviar la instrucción final al Payment Execution System (PES) después de la autorización, asegurando el débito/crédito en el Core." "Spring Webflux/WebClient" {
                                tags "Component"
                            }
                            
                            rsaEncryptionComponent = component "RSA Cryptography Service" "Gestiona el cifrado y descifrado simétrico de datos confidenciales mediante claves públicas/privadas RSA." "Spring Security/JCA (Java)" {
                                tags "Seguridad", "Compliance"
                            }
                            
                            auditClient = component "Audit System Client" "Componente responsable de publicar eventos de las acciones del cliente en el Message Broker para el registro asíncrono en el Audit System." "Azure Event Hubs SDK" {
                                tags "Component"
                            }
                            
                            notificationPublisher = component "Notification Event Publisher" "Componente responsable de publicar eventos de notificaciones transaccionales al Message Broker para el envío asíncrono de Email, SMS o Push." "Azure Event Hubs SDK" {
                                tags "Component"
                            }
                            
                            paymentController -> paymentOrchestrator "Delega la orquestación del proceso"
                            
                            paymentOrchestrator -> tasClient "Solicita la autorización antes de la ejecución de pago"
                            paymentOrchestrator -> redisClient "Valida si la operacion fue ejecutada (Cache-Aside)"
                            paymentOrchestrator -> pesClient "Solicita la ejecución de pago después de la autorización y verificación de fraude"
                            paymentOrchestrator -> rsaEncryptionComponent "Utiliza para descifrar payload o headers"
                            paymentOrchestrator -> coreClient "Busca informacion de contactabilidad para notificacion de operacion exitosa"
                            paymentOrchestrator -> auditClient "Publica el evento 'Transferencia Realizada' para auditoría"
                            paymentOrchestrator -> notificationPublisher "Publica el evento 'Notificar Transferencia Realizada' al cliente"
                        }
                    }
                }
            }
            
            customer -> digitalbanking.spa "Realiza pago de servicio"
            customer -> digitalbanking.mobile "Realiza pago de servicio"
            
            digitalbanking.spa -> apiGateway "Realiza llamadas API/HTTP Sourcing. Informacion DAC se envia cifrada en RSA con llaves para integracion desde el internet." "TLS-HTTPS/JSON"
            digitalbanking.mobile -> apiGateway "Realiza llamadas API/HTTP Sourcing. Informacion DAC se envia cifrada en RSA con llaves para integracion desde el internet." "TLS-HTTPS/JSON"
            
            apiGateway -> digitalbankingService.serviceController "Rutas de las solicitudes a la API/Se balancea Prod/Cont segun situacion" "JSON/HTTPS"
            
            digitalbankingService.identityClient -> identitySystem.authenticationService "Obtiene datos de sesion realizado por usuario" "TCP/IP"
            digitalbankingService.paymentInitiationClient -> paymentInitiationService "Proporciona listo de comercios y pago de servicios. Informacion DAC se envia cifrada en RSA con llaves para integracion desde la red interna." "API/HTTPS"

            paymentInitiationService.redisClient -> digitalbanking.cache "Obtiene validacion de transaccion existente en proceso o culminado." "TCP/IP"
            paymentInitiationService.coreClient -> coreNewSystem "Obtienes datos de contactabilidad de cliente para notificacion." "API/MTLS-HTTPS"
            paymentInitiationService.tasClient -> transactionAuthorizationService "Envia validacion y autorizacion de transaccion." "API/HTTPS"
            paymentInitiationService.pesClient -> paymentExecutionService "Solicita ejecucion de pago de servicio." "API/HTTPS"
            paymentInitiationService.notificationPublisher -> notificationSystem.notificationBroker "Envia notificacion de pago exitoso o fallido." "TCP/IP"
            paymentInitiationService.auditClient -> auditSystem.messageBroker "Registra resultado de transaccion realizada." "TCP/IP"
            
            transactionAuthorizationService -> coreLegacyService "Valida saldo vigente para transaccion" "API/HTTPS"
            transactionAuthorizationService -> notificationSystem.notificationBroker "Envia notificacion OTP de confirmacion" "API/HTTPS"
            transactionAuthorizationService -> fraudDetectionService "Envia validacion de frande de transaccion" "API/HTTPS"
            
            paymentExecutionService -> clickToPayService "Procesa pago de servicio y obtiene codigo de operacion" "API/MTLS-HTTPS"
            paymentExecutionService -> coreLegacyService "Registra pago de servicio realizado con codigo de operacion" "API/HTTPS"
            
            coreLegacyService -> coreLegacySystem "Reads/writes information/transaction core" "TCP/IP"
        }
    }

    views {
        systemLandScape digitalbanking "DigitalBanking" {
            include *
            autolayout lr
        }
        systemContext digitalbanking "DigitalBanking" {
            include *
            autolayout lr
        }
        systemContext auditSystem "AuditSystem" {
            include *
            autolayout lr
        }
        systemContext identitySystem "IdentitySystem" {
            include *
            autolayout lr
        }
        systemContext notificationSystem "NotificationSystem" {
            include *
            autolayout lr
        }
        
        container digitalbanking "DigitalBankingContainer" {
            include *
            autolayout lr
        }
        container auditSystem "AuditContainer" {
            include *
            autolayout lr
        }
        container notificationSystem "NotificationContainer" {
            include *
            autolayout lr
        }
        container identitySystem "IdentityContainer" {
            include *
            autolayout tb
        }
        
        component digitalbanking.paymentInitiationService "PaymentInitiationComponent" {
            include *
            autolayout lr
        }
        component digitalbanking.digitalbankingService "DigitalBankingService" {
            include *
            autolayout lr
        }

        styles {
            element "Element" {
                strokeWidth 6
            }
            element "Person" {
                stroke #000000
                background #f2f2f2
                shape person
                fontSize 23
            }
            element "Internal" {
                stroke #999999
                color #999999
                fontSize 23
                shape roundedbox
            }
            element "External" {
                stroke #ff9837
                color #ff9837
                fontSize 23
                shape roundedbox
            }
            element "DigitalBanking" {
                background #1168bd
                color #ffffff
                fontSize 23
                shape roundedbox
            }
            element "File" {
                stroke #1168bd
                color #1168bd
                shape Folder
                fontSize 23
            }
            element "Web" {
                stroke #1168bd
                color #1168bd
                shape WebBrowser
                fontSize 23
            }
            element "App" {
                stroke #1168bd
                color #1168bd
                shape MobileDevicePortrait
                fontSize 23
            }
            element "Broker" {
                stroke #a10f59
                color #a10f59
                shape Pipe
                fontSize 23
            }
            element "Database" {
                stroke #6c3687
                color #6c3687
                shape Cylinder
                fontSize 23
            }
            element "Microservice" {
                stroke #1168bd
                color #1168bd
                shape RoundedBox
                fontSize 23
            }
            element "Api" {
                stroke #1168bd
                color #1168bd
                shape RoundedBox
                fontSize 23
            }
            element "Function" {
                stroke #1168bd
                color #1168bd
                shape Hexagon
                fontSize 23
            }
            element "Component" {
                stroke #1168bd
                color #1168bd
                shape Component
                fontSize 23
                Width 550
                Metadata true
            }
            element "Pattern: ACL" {
                color #ff0000
                border dashed
            }
            element "Pattern: Orchestrator" {
                color #ff0000
                border dashed
            }
            element "Pattern: Event Consumer" {
                color #a10f59
                border dashed
            }
            element "Compliance" {
                color #008000
                border solid
            }
            element "Pattern: Strangler Fig" {
            color #b300b3
            border dashed
        }
        }
    }
}
