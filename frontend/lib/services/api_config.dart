// API configuration: the one compile-time backend base URL used by all services.
const apiBaseUrl = String.fromEnvironment(
  'COWORK_API_BASE',
  defaultValue: 'http://localhost:8080/api',
);
