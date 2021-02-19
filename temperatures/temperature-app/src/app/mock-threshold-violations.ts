import { ThresholdViolation } from './threshold-violation';

export const VIOLATIONS: ThresholdViolation[] = [
   { timestamp: "2020-02-02T14:03:00Z", temperature: 79, threshold: 78},
   { timestamp: "2020-02-02T14:04:00Z", temperature: 79.4, threshold: 78},
   { timestamp: "2020-02-02T14:05:00Z", temperature: 79.3, threshold: 78},
   { timestamp: "2020-02-02T14:06:00Z", temperature: 79.5, threshold: 78},
   { timestamp: "2020-02-02T14:07:00Z", temperature: 79.8, threshold: 78}
]
