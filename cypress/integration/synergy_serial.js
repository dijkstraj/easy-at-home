context('Synergy', () => {
  it('fetch serial', () => {
    cy.visit('https://members.symless.com/synergy/downloads/list/s1');
    cy.get('#email')
      .type(Cypress.env('EMAIL'));
    cy.get('#password')
      .type(Cypress.env('PASSWORD'));
    cy.contains('button', 'Login')
      .click();
    cy.get('#serialkeytext')
      .then(($serial) => {
        cy.writeFile('/tmp/synergy.serial', $serial.val(), 'utf-8');
      });
    cy.request({
      method: 'GET',
      url: 'https://members.symless.com/synergy/download/direct?platform=ubuntu20&architecture=x64',
      followRedirect: false
    }).then((response) => {
      cy.writeFile('/tmp/synergy.deb.url', response.headers.location, 'utf-8');
    });
  });
});
