import { Injectable } from '@angular/core';
import { ThresholdViolation } from './threshold-violation';
import { Observable, of, timer } from 'rxjs';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { MessageService } from './message.service';
import { switchMap } from 'rxjs/operators';

@Injectable({
  providedIn: 'root'
})
export class ViolationService {

  private eci = 'ckld69zv4000j1ei074l78t6z';
  private rid = 'com.tcashcroft.temperature_store';
  private function = 'threshold_violations';
  private violationsUrl = ''.concat('http://localhost:3000/sky/cloud/', this.eci, '/', this.rid, '/', this.function);

  private violations: Observable<ThresholdViolation[]>;

  constructor(private http: HttpClient, private messageService: MessageService) {
    this.violations = timer(1, 10000).pipe(
	    switchMap(() => this.http.get<ThresholdViolation[]>(this.violationsUrl))
    );
  }

  getViolations(): Observable<ThresholdViolation[]> {
    //this.messageService.add(this.violationsUrl);
    //return this.http.get<ThresholdViolation[]>(this.violationsUrl);
    return this.violations;
  }
}
