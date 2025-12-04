const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../server');
const { VolunteerProfile, User, SosCase } = require('../models');

describe('🧪 Kiểm tra Controller Tình Nguyện Viên', () => {
    let tokenXacThuc;
    let maTNV;
    let maNguoiDung;

    beforeAll(async () => {
        // Kết nối database test
        await mongoose.connect(process.env.MONGODB_URI_TEST || process.env.MONGODB_URI);
    });

    afterAll(async () => {
        // Dọn dẹp và đóng kết nối
        await mongoose.connection.close();
    });

    describe('POST /api/volunteers/me/toggle-ready - Bật/Tắt Sẵn Sàng', () => {
        beforeEach(async () => {
            // Tạo tài khoản test
            const nguoiDungTest = await User.create({
                fullName: 'TNV Test',
                email: `test${Date.now()}@example.com`,
                phone: `099${Math.floor(Math.random() * 10000000)}`,
                password: 'password123',
                roles: ['TNV_CN'],
                isActive: true
            });

            maNguoiDung = nguoiDungTest._id;

            const tnvTest = await VolunteerProfile.create({
                userId: nguoiDungTest._id,
                type: 'CN',
                homeBase: {
                    location: {
                        type: 'Point',
                        coordinates: [106.6500, 10.8500] // TP.HCM
                    },
                    radiusKm: 5
                },
                status: 'APPROVED',
                ready: false
            });

            maTNV = tnvTest._id;

            // Đăng nhập để lấy token
            const ketQuaDangNhap = await request(app)
                .post('/api/auth/login')
                .send({
                    email: nguoiDungTest.email,
                    password: 'password123'
                });

            tokenXacThuc = ketQuaDangNhap.body.token;
        });

        afterEach(async () => {
            // Xóa dữ liệu test
            await VolunteerProfile.deleteMany({ userId: maNguoiDung });
            await User.deleteMany({ _id: maNguoiDung });
        });

        it('✅ Chuyển từ Tắt sang Bật thành công', async () => {
            const ketQua = await request(app)
                .patch('/api/volunteers/me/toggle-ready')
                .set('Authorization', `Bearer ${tokenXacThuc}`)
                .expect(200);

            expect(ketQua.body.success).toBe(true);
            expect(ketQua.body.data.ready).toBe(true);
            expect(ketQua.body.message).toContain('ACTIVE');
        });

        it('✅ Chuyển từ Bật sang Tắt thành công', async () => {
            // Đặt ready = true trước
            await VolunteerProfile.findByIdAndUpdate(maTNV, { ready: true });

            const ketQua = await request(app)
                .patch('/api/volunteers/me/toggle-ready')
                .set('Authorization', `Bearer ${tokenXacThuc}`)
                .expect(200);

            expect(ketQua.body.success).toBe(true);
            expect(ketQua.body.data.ready).toBe(false);
            expect(ketQua.body.message).toContain('INACTIVE');
        });

        it('❌ Thất bại khi không có token', async () => {
            const ketQua = await request(app)
                .patch('/api/volunteers/me/toggle-ready')
                .expect(401);

            expect(ketQua.body.success).toBe(false);
        });

        it('❌ Thất bại khi người dùng không phải TNV', async () => {
            // Tạo tài khoản người dùng thường
            const nguoiDungThuong = await User.create({
                fullName: 'Người Dùng Thường',
                email: `user${Date.now()}@example.com`,
                phone: `098${Math.floor(Math.random() * 10000000)}`,
                password: 'password123',
                roles: ['USER'],
                isActive: true
            });

            const ketQuaDangNhap = await request(app)
                .post('/api/auth/login')
                .send({
                    email: nguoiDungThuong.email,
                    password: 'password123'
                });

            const ketQua = await request(app)
                .patch('/api/volunteers/me/toggle-ready')
                .set('Authorization', `Bearer ${ketQuaDangNhap.body.token}`)
                .expect(403);

            expect(ketQua.body.success).toBe(false);
            expect(ketQua.body.message).toContain('Only volunteers');

            // Dọn dẹp
            await User.deleteOne({ _id: nguoiDungThuong._id });
        });
    });
});
