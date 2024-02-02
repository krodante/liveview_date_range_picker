const DaterangeHover = {
  mounted() {
    const id = '#' + this.el.id;
    this.el.addEventListener('mouseover', (e) => {
      if (e.target.type == "button") {
        this.pushEventTo(id, 'cursor-move', e.target.getAttribute('phx-value-date'));
      }
    });
  }
};

export default DaterangeHover;
