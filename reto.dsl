workspace "Reto" "Arquitectura de Integracion" {

    !identifiers hierarchical

    model {
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
        
        clickToPayService = softwareSystem "Click to Pay" "Proveedor Thales, C2P estándar de pago externo (basado en EMV SRC) que permite el pago sin tarjeta mediante un identificador digital." {
            tags "External"
        }
        
        auditSystem = softwareSystem "Audit System" "Gestiona el registro, almacenamiento y recuperación de todas las acciones del consumidor." {
            tags "Internal"
            
            messageBroker = container "Message Broker" "Un bus de eventos para la comunicación asíncrona y desacoplada entre servicios." "Event Hubs" {
                tags "Broker"
            }
            
            auditService = container "Audit Service" "Gestiona la persistencia de los eventos del registro de auditoría de forma asíncrona." "Azure Function/Spring Boot" {
                tags "Function"
            }
            
            auditDatabase = container "Audit Database" "Una base de datos relacional para almacenar todos los registros de auditoría de acciones del cliente." "PostgreSQL" {
                tags "Database"
            }
            
            auditService -> messageBroker "Consume eventos de auditoría" "Event Driven/AMQP"
            auditService -> messageBroker "Notificación de reintento posterior para eventos de error (3)" "AMQP"
            auditService -> auditDatabase "Escribe registro de auditoría" "JDBC/TLS"
        }
        
        identitySystem = softwareSystem "Identity System" "Sistema de identidad de usuario que utiliza servicios externos para gestionar la autenticación." {
            tags "Internal"
            
            onboardingService = container "Onboarding Service" "Gestiona el registro de nuevos clientes y la verificación biométrica facial." {
                tags "Microservice"
            }
            
            authenticationService = container "Authenticate Service" "El servicio OAuth2.0 existente de la compañía para gestionar la autenticación de usuarios." {
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
                tags "Function"
            }
            
            notifyDatabase = container "Notify Database" "Una base de datos relacional para almacenar todos los registros de auditoría de acciones del cliente." "PostgreSQL" {
                tags "Database"
            }
            
            acs = container "Azure Communication Services" "Plataforma como servicio (PaaS) para el envío de correos electrónicos y SMS transaccionales." {
                tags "External"
            }
            
            anh = container "Azure Notification Hubs" "Plataforma como servicio (PaaS) para gestionar y enviar notificaciones push multiplataforma." {
                tags "External"
            }
            
            azureStorageAccount = container "Azure Storage Account" "Cloud storage used to host static assets, specifically HTML templates for email notifications." {
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
            
            spa = container "Web Application" "Aplicación web de una sola página (SPA) orientada al cliente, desarrollada con React, que se ejecuta en el navegador." "Reac" {
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
            
            group "Azure Kubernetes Geo-replication - Autoscaling pod for demand" {
            
                digitalbankingService = container "Experience Bank Service" "Servicio encargado de coordinar las integraciones necesarias para facilitar la integración con la interfaz de usuario." "BFF Pattern" {
                    tags "Microservice"
                }
                
                fraudDetectionService = container "Fraud Detection" "Un servicio especializado en tiempo real que evalúa la puntuación de riesgo de una transacción basándose en datos conductuales, históricos y contextuales." {
                    tags "Microservice"
                }
                
                coreLegacyService = container "Conector Core Legacy Service" "Construyendo un conector centralizado que sirva de interfaz con el sistema core (legacy)." "Spring Boot" {
                    tags "Microservice"
                }
                
                paymentInitationService = container "Payment Initation" "Gestiona la lógica empresarial y la orquestación de todas las validacion y pagos de servicio." "Azure Function/Spring Boot" {
                    tags "Microservice"
                }
                
                transactionAuthorizationService = container "Transaction Authorization" "Un sistema que evalúa las solicitudes de transacciones en tiempo real según motores de reglas (límites, riesgo, puntuaciones de fraude) para emitir aprobaciones o rechazos." {
                    tags "Microservice"
                }
                
                paymentExecutionService = container "Payment Execution" "El sistema central responsable de registrar los débitos y créditos reales de fondos, interactuando directamente con las infraestructuras de pago externas." {
                    tags "Microservice"
                }
            }
            
            customer -> digitalbanking.spa "Realiza pago de servicio"
            customer -> digitalbanking.mobile "Realiza pago de servicio"
            
            digitalbanking.spa -> apiGateway "Realiza llamadas API/HTTP Sourcing. Informacion DAC se envia cifrada en RSA con llaves para integracion desde el internet." "TLS-HTTPS/JSON"
            digitalbanking.mobile -> apiGateway "Realiza llamadas API/HTTP Sourcing. Informacion DAC se envia cifrada en RSA con llaves para integracion desde el internet." "TLS-HTTPS/JSON"
            
            apiGateway -> digitalbankingService "Rutas de las solicitudes a la API." "JSON/HTTPS"
            
            digitalbankingService -> identitySystem.cache "Obtiene datos de sesion realizado por usuario" "TCP/IP"
            digitalbankingService -> paymentInitationService "Proporciona listo de comercios y pago de servicios. Informacion DAC se envia cifrada en RSA con llaves para integracion desde la red interna." "API/HTTPS"

            paymentInitationService -> cache "Obtiene validacion de transaccion existente en proceso o culminado." "TCP/IP"
            paymentInitationService -> coreNewSystem "Obtienes datos de contactabilidad de cliente para notificacion." "API/MTLS-HTTPS"
            paymentInitationService -> transactionAuthorizationService "Envia validacion y autorizacion de transaccion." "API/HTTPS"
            paymentInitationService -> paymentExecutionService "Solicita ejecucion de pago de servicio." "API/HTTPS"
            paymentInitationService -> notificationSystem.notificationBroker "Envia notificacion de pago exitoso o fallido." "TCP/IP"
            paymentInitationService -> auditSystem.messageBroker "Registra resultado de transaccion realizada." "TCP/IP"
            
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
        }
    }
}