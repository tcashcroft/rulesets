import { Component, OnInit } from '@angular/core';
import { ThresholdViolation } from '../threshold-violation';
import { ViolationService } from '../violation.service';

@Component({
  selector: 'app-threshold-violation-history',
  templateUrl: './threshold-violation-history.component.html',
  styleUrls: ['./threshold-violation-history.component.css']
})
export class ThresholdViolationHistoryComponent implements OnInit {

  violations: ThresholdViolation[];

  constructor(private violationService: ViolationService) { }

  ngOnInit(): void {
    this.getViolations();
  }

  getViolations(): void {
    this.violationService.getViolations().subscribe(violations => this.violations = violations.reverse());
  }

}
