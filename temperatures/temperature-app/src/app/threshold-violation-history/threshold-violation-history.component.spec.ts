import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ThresholdViolationHistoryComponent } from './threshold-violation-history.component';

describe('ThresholdViolationHistoryComponent', () => {
  let component: ThresholdViolationHistoryComponent;
  let fixture: ComponentFixture<ThresholdViolationHistoryComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ ThresholdViolationHistoryComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(ThresholdViolationHistoryComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
