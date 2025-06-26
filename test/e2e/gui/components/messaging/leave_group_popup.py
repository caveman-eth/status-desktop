import allure

from gui.elements.button import Button
from gui.elements.object import QObject
from gui.objects_map import names


class LeaveGroupPopup(QObject):

    def __init__(self):
        super().__init__(names.confirmationDialog)
        self.leave_button = Button(names.leave_StatusButton)

    @allure.step("Confirm leaving group")
    def confirm_leaving(self):
        self.leave_button.click()
        self.wait_until_hidden()

