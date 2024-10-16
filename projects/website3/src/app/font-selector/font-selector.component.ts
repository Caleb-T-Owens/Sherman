import { afterNextRender, ChangeDetectorRef, Component } from '@angular/core'

@Component({
  selector: 'cto-font-selector',
  standalone: true,
  template: `
    <fieldset class="font-size-selector">
      <legend>Font size</legend>
      <div>
        <input
          type="radio"
          name="font-size"
          id="font-small"
          value="small"
          [checked]="smallSelected"
          (change)="onChange($event)"
        />
        <label for="font-small">Small</label>
      </div>
      <div>
        <input
          type="radio"
          name="font-size"
          id="font-medium"
          value="medium"
          [checked]="mediumSelected"
          (change)="onChange($event)"
        />
        <label for="font-medium">Medium</label>
      </div>
      <div>
        <input
          type="radio"
          name="font-size"
          id="font-large"
          value="large"
          [checked]="largeSelected"
          (change)="onChange($event)"
        />
        <label for="font-large">Large</label>
      </div>
    </fieldset>
  `,
  styles: `
    .font-size-selector {
      width: fit-content;
      margin-bottom: 1rem;

      > div {
        display: inline-flex;
        align-items: center;

        margin-right: 1rem;

        &:last-child {
          margin-right: 0.5rem;
        }
      }
    }
  `,
})
export class FontSelectorComponent {
  smallSelected = false
  mediumSelected = false
  largeSelected = false

  constructor(private changeDetection: ChangeDetectorRef) {
    afterNextRender(() => {
      const initialFontSize =
        localStorage.getItem('selected-font-size') || 'medium'
      this.updateHtmlStyles(initialFontSize)

      this.changeDetection.detectChanges()
    })
  }

  onChange(event: Event) {
    const value = (event.target! as HTMLInputElement).value
    this.updateHtmlStyles(value)
  }

  updateHtmlStyles(size: string) {
    localStorage.setItem('selected-font-size', size)

    this.smallSelected = false
    this.mediumSelected = false
    this.largeSelected = false
    switch (size) {
      case 'small':
        this.smallSelected = true
        break
      case 'medium':
        this.mediumSelected = true
        break
      case 'large':
        this.largeSelected = true
        break
    }

    const html = document.querySelector('html')!
    html.classList.toggle('font-small', this.smallSelected)
    html.classList.toggle('font-medium', this.mediumSelected)
    html.classList.toggle('font-large', this.largeSelected)
  }
}
