# Monitoring and Observability

To maintain a healthy platform, we need to understand what is happening inside it at all times. We use a set of tools often referred to as the **PLGT Stack** (Prometheus, Loki, Grafana, Tempo).

## 1. The Visualization Layer: Grafana

**Grafana** is the "single pane of glass". It is the web interface where we view all our data. It doesn't store data itself; it pulls data from the other three components and displays it in beautiful dashboards.

*   **Role:** Visualization & Alerting.
*   **User Example:** A Product Manager opens Grafana to see a dashboard showing "Daily Active Users" or "Number of Orders Processed Today".

## 2. The Data Sources (The "Backend")

We collect three types of data (often called the "Three Pillars of Observability").

### A. Metrics (Prometheus)
**Metrics** are numbers that change over time. They tell us "How much?" or "How many?".
*   **Tool:** Prometheus (collected by Grafana Alloy).
*   **What it tracks:** CPU usage, memory consumption, number of requests per second, error rates.
*   **User Example:** "Is the system slow right now?" -> We check the "Response Time" metric. If it jumped from 200ms to 2s, we know there is a problem.

### B. Logs (Loki)
**Logs** are text records of events. They tell us "What happened?".
*   **Tool:** Loki.
*   **What it tracks:** Application startup messages, error descriptions, transaction details.
*   **User Example:** "Why did this specific order fail?" -> We search Loki for the Order ID and see a log entry: `Error: Payment Gateway Timeout`.

### C. Traces (Tempo)
**Traces** follow a single request as it travels through multiple microservices. They tell us "Where did it go?".
*   **Tool:** Tempo.
*   **What it tracks:** The path of a request from Frontend -> Order Service -> Database.
*   **User Example:** "The login is slow. Is it the Frontend or the Database?" -> We look at the trace. It shows the Frontend took 10ms, but the Database query took 5 seconds. We know the Database is the bottleneck.

## Diagram: How Data Flows

```mermaid
graph LR
    subgraph Applications
    App[Microservice]
    end

    subgraph Collection
    Alloy[Grafana Alloy (Collector)]
    end

    subgraph Storage
    Prom[Prometheus (Metrics)]
    Loki[Loki (Logs)]
    Tempo[Tempo (Traces)]
    end

    subgraph Visualization
    Grafana[Grafana UI]
    User[User]
    end

    App -->|Sends Telemetry| Alloy
    Alloy -->|Writes Metrics| Prom
    Alloy -->|Writes Logs| Loki
    Alloy -->|Writes Traces| Tempo

    Grafana -->|Queries| Prom
    Grafana -->|Queries| Loki
    Grafana -->|Queries| Tempo

    User -->|Views Dashboards| Grafana
```

## Alerting

We don't want to stare at dashboards all day. **Alerting** notifies us when something is wrong.
*   **Example:** If the "Error Rate" metric goes above 5% for more than 5 minutes, Grafana sends a message to our Slack channel.
